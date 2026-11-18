import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:track_loved/DrawerScreen/AddNetworkScreen/AddNetWorkScreen.dart';
import 'package:track_loved/DrawerScreen/NetworkLocationpermissions.dart';
import 'package:track_loved/HomeScreen/NotificationScreen.dart';
import 'package:track_loved/LoginScreen/AdultOnboardingScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/SettingScreen/SettingScreen.dart';
import 'package:track_loved/core/Data/ResponseModel/getDashboardModel.dart';
import 'package:track_loved/core/Utils/FcmNotificationService.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

import '../core/Data/BodyModel/TriggerSosBodyModel.dart';
import 'provider/getDashbordProvider.dart';

class DynamicDashboardScreen extends ConsumerStatefulWidget {
  const DynamicDashboardScreen({super.key});

  @override
  ConsumerState<DynamicDashboardScreen> createState() =>
      _DynamicDashboardScreenState();
}

class _DynamicDashboardScreenState extends ConsumerState<DynamicDashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<Position>? _locationSub;
  Timer? _heartbeatTimer;
  static const double _minDistanceMeters = 5;
  static const Duration _minInterval = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(minutes: 1);
  bool _askedAlwaysPermission = false;
  bool _isStarting = false;
  Position? _lastSent;
  DateTime? _lastSentAt;
  io.Socket? _ageOutSocket;
  bool _isExtendingPermissions = false;
  bool _isDismissingPermissions = false;
  bool _actionTakenInSession = false;
  String? _loadingActionFriendId;
  final Set<String> _locallyHandledFriendIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureHiveOpen();
    _checkPermissions();
    _checkAgeOutGate();
    _initAgeOutSocket();
    _startLocationUpdates();
    FcmNotificationService.dashboardRefreshNotifier.addListener(
      _onFcmDashboardRefresh,
    );
  }

  void _onFcmDashboardRefresh() {
    if (mounted) {
      log(
        '[Dashboard] Auto-refreshing dashboard due to FCM expiring notification',
      );
      _actionTakenInSession = false;
      _locallyHandledFriendIds.clear();
      ref.invalidate(getDashbordProvider);
    }
  }

  void _checkAgeOutGate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      final role = box?.get('role')?.toString().toLowerCase();
      final requiresAdult =
          box?.get('requiresAdultReconsent') == true ||
          role == 'adult_pending_consent';
      if (requiresAdult) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AdultOnboardingScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  void _initAgeOutSocket() {
    try {
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      final role = box?.get('role')?.toString().toLowerCase();
      if (role == 'user' || role == 'adult') return;

      final userId =
          box?.get('id')?.toString() ?? box?.get('userId')?.toString();
      final phone = box?.get('phone')?.toString();

      final socket = io.io(
        'https://loveable-backend-5qi0.onrender.com',
        // 'https://api.tracklovedones.com',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );
      _ageOutSocket = socket;

      void handleAgeOut(dynamic data) async {
        log('[AgeOutSocket] Age-out event triggered received: $data');
        final uBox = Hive.isBoxOpen('userdata')
            ? Hive.box('userdata')
            : await Hive.openBox('userdata');
        await uBox.put('requiresAdultReconsent', true);
        await uBox.put('role', 'adult_pending_consent');

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AdultOnboardingScreen(),
            ),
            (route) => false,
          );
        }
      }

      socket.on('age_out_triggered', handleAgeOut);
      if (userId != null && userId.isNotEmpty) {
        socket.on('age_out_triggered_$userId', handleAgeOut);
      }
      if (phone != null && phone.isNotEmpty) {
        socket.on('age_out_triggered_$phone', handleAgeOut);
      }
    } catch (e) {
      log('[AgeOutSocket] Init error: $e');
    }
  }

  Future<void> _ensureHiveOpen() async {
    if (!Hive.isBoxOpen('userdata')) {
      await Hive.openBox('userdata');
      if (mounted) setState(() {});
    }
    try {
      final box = Hive.box('userdata');
      await box.delete('location_permission_alert_dismissed_until');
    } catch (_) {}
  }

  Future<void> _startLocationUpdates() async {
    // initState and the resume callback can both call this at once.
    if (_isStarting) return;
    _isStarting = true;
    try {
      await _doStartLocationUpdates();
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _doStartLocationUpdates() async {
    await _locationSub?.cancel();
    _locationSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      // iOS shows a normal dialog for "Always". On Android 11+ that choice
      // opens the system settings page, and the foreground service already
      // keeps updates running in background with "while using" permission.
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          !_askedAlwaysPermission &&
          !await Permission.locationAlways.isGranted) {
        _askedAlwaysPermission = true;
        await Permission.locationAlways.request();
      }
      // Fires when the user moves at least 5 metres.
      _locationSub = Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).listen(_sendLocation);
      // Send the starting point once with maximum precision
      try {
        final initPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 8),
          ),
        );
        _sendLocation(initPos);
      } catch (_) {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) _sendLocation(lastPos);
      }
      _startHeartbeatTimer();
    } catch (e) {
      debugPrint('Location stream failed: $e');
    }
  }

  LocationSettings _buildLocationSettings() {
    const accuracy = LocationAccuracy.bestForNavigation;
    const distanceFilter = 5; // keep in sync with _minDistanceMeters
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: const Duration(seconds: 5),
        forceLocationManager: false,
        // Foreground service keeps updates alive when the app is in background.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Track Loved',
          notificationText:
              'Sharing precise live location with your trusted network',
          notificationChannelName: 'Location Service',
          enableWakeLock: true,
          setOngoing: false,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (!mounted) return;
      // If a regular movement-based update was already sent recently (< 50 sec), skip this heartbeat
      if (_lastSentAt != null &&
          DateTime.now().difference(_lastSentAt!).inSeconds < 50) {
        return;
      }
      await _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    try {
      Position? pos = _lastSent;
      pos ??= await Geolocator.getLastKnownPosition();
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (_) {}
      }
      if (pos != null) {
        _lastSent = pos;
        _lastSentAt = DateTime.now();
        log('[Location Heartbeat] sending ${pos.latitude}, ${pos.longitude}');
        await ref
            .read(authServiceProvider)
            .updateUserLocationData(
              latitude: pos.latitude,
              longitude: pos.longitude,
            );
        log('[Location Heartbeat] sent OK');
      }
    } catch (e) {
      log('[Location Heartbeat] FAILED: $e');
    }
  }

  Future<void> _sendLocation(Position position) async {
    // GPS can fire rapidly (drift, emulator): only send real movement.
    final last = _lastSent;
    if (last != null) {
      final moved = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );
      final elapsed = DateTime.now().difference(_lastSentAt!);
      final isStationaryHeartbeat = elapsed >= _heartbeatInterval;
      if (!isStationaryHeartbeat &&
          (moved < _minDistanceMeters || elapsed < _minInterval)) {
        log(
          '[Location] skipped: moved ${moved.toStringAsFixed(1)} m, '
          '${elapsed.inSeconds}s since last send',
        );
        return;
      }
    }
    _lastSent = position;
    log('[Location] sending ${position.latitude}, ${position.longitude}');
    _lastSentAt = DateTime.now();
    try {
      await ref
          .read(authServiceProvider)
          .updateUserLocationData(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      log('[Location] sent OK');
    } catch (e) {
      log('[Location] update FAILED: $e');
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    FcmNotificationService.dashboardRefreshNotifier.removeListener(
      _onFcmDashboardRefresh,
    );
    _ageOutSocket?.disconnect();
    _ageOutSocket?.dispose();
    _ageOutSocket = null;
    _locationSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      // Already streaming (incl. in background): do not restart on every resume.
      if (_locationSub == null) _startLocationUpdates();
    }
  }

  Future<void> _checkPermissions() async {
    final locationGranted = await Permission.location.isGranted;
    final contactsGranted = await Permission.contacts.isGranted;
    if (!locationGranted || !contactsGranted) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationConsentScreen(),
          ),
        );
      }
    }
  }

  bool _isAlertLocallyMuted() {
    return _actionTakenInSession;
  }

  Future<void> _recordAlertActionTaken() async {
    _actionTakenInSession = true;
    if (mounted) setState(() {});
  }

  Future<void> _executeLocationSharingAction({
    required bool isRenew,
    dynamic userIds,
    bool isAll = false,
    String? individualFriendId,
    BuildContext? dialogContext,
    void Function(void Function())? updateSheetState,
    VoidCallback? onSuccess,
  }) async {
    if (_isExtendingPermissions || _isDismissingPermissions) return;
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (isRenew) {
          _isExtendingPermissions = true;
        } else {
          _isDismissingPermissions = true;
        }
        _loadingActionFriendId = individualFriendId;
      });
    }
    if (updateSheetState != null) {
      updateSheetState(() {});
    }

    try {
      final service = ref.read(authServiceProvider);
      final res = isAll
          ? await service.locationSharingActionData(
              locationAccessRenewAll: isRenew ? true : null,
              locationAccessDisableAll: !isRenew ? true : null,
            )
          : await service.locationSharingActionData(
              locationAccessRenew: isRenew ? true : null,
              locationAccessDisable: !isRenew ? true : null,
              userIds: userIds,
            );

      if (userIds is String) {
        _locallyHandledFriendIds.add(userIds);
      } else if (userIds is List) {
        for (final id in userIds) {
          _locallyHandledFriendIds.add(id.toString());
        }
      } else if (isAll) {
        _locallyHandledFriendIds.clear();
      }

      if (isAll) {
        await _recordAlertActionTaken();
      } else {
        _actionTakenInSession = false;
      }

      if (onSuccess != null) {
        onSuccess();
      }

      ref.invalidate(getDashbordProvider);

      if (dialogContext != null && dialogContext.mounted && isAll) {
        Navigator.of(dialogContext).pop();
      }

      if (mounted) {
        showSuccessSnackBar(
          res.message ??
              (isRenew
                  ? 'Expiring location access was renewed.'
                  : 'Location sharing was disabled for the selected friends.'),
          context,
        );
      }
    } catch (e) {
      log('[Dashboard] Error performing location sharing action: $e');
      if (mounted) {
        // showErrorSnackBar('Action failed: $e', context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtendingPermissions = false;
          _isDismissingPermissions = false;
          _loadingActionFriendId = null;
        });
      }
      if (updateSheetState != null) {
        updateSheetState(() {});
      }
    }
  }

  void _handleManageManually({BuildContext? dialogContext}) async {
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}

    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkLocationPermissionsScreen(),
        ),
      );
      if (mounted) {
        _actionTakenInSession = false;
        _locallyHandledFriendIds.clear();
        ref.invalidate(getDashbordProvider);
      }
    }
  }

  Widget _buildLocationPermissionExpiryBanner({
    List<SystemAlertItem> items = const [],
    LocationPermissionAlert? locAlert,
  }) {
    final allItems = <SystemAlertItem>[];
    if (items.isNotEmpty) {
      allItems.addAll(items);
    } else if (locAlert != null) {
      allItems.add(
        SystemAlertItem(
          friendId: locAlert.friendId,
          message: locAlert.message,
          friendName: locAlert.friendName,
          minutesRemaining: locAlert.minutesRemaining,
          isExpiring: locAlert.isExpiring,
          isExpired: locAlert.isExpired,
          canRenew: locAlert.canRenew,
        ),
      );
    }

    allItems.removeWhere(
      (item) =>
          item.friendId != null &&
          _locallyHandledFriendIds.contains(item.friendId),
    );

    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final isExpired =
        allItems.any((item) => item.isExpired == true) ||
        (locAlert?.isExpired == true);
    final count = allItems.length;

    final badgeText = isExpired
        ? (count > 1 ? 'PERMISSIONS EXPIRED ($count)' : 'PERMISSION EXPIRED')
        : (count > 1
              ? 'SYSTEM ALERTS ($count)'
              : (allItems.isNotEmpty &&
                        allItems.first.minutesRemaining != null &&
                        allItems.first.minutesRemaining! > 0
                    ? 'EXPIRING IN ${allItems.first.minutesRemaining} MIN'
                    : 'SYSTEM ALERT'));

    final badgeColor = isExpired
        ? const Color(0xFFC62828)
        : const Color(0xFFE65100);
    final badgeBg = isExpired
        ? const Color(0xFFFFCDD2)
        : const Color(0xFFFFE0B2);

    final title = count > 1
        ? (isExpired
              ? 'Location permissions expired for $count contacts'
              : 'Location permissions are about to expire for $count contacts')
        : (allItems.isNotEmpty &&
                  allItems.first.message?.trim().isNotEmpty == true
              ? allItems.first.message!
              : (isExpired
                    ? 'Location permission expired'
                    : 'Your location permissions are about to expire'));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? const Color(0xFFEF9A9A) : const Color(0xFFFFB74D),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isExpired ? Colors.red : Colors.orange).withValues(
              alpha: 0.08,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isExpired ? Icons.error_outline : Icons.warning_amber_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // List each contact cleanly
          if (allItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExpired
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFFFE0B2),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: allItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final itemExpired = item.isExpired == true;
                  final friendName = item.friendName ?? 'Contact';
                  final friendId = item.friendId;
                  final minLeft = item.minutesRemaining;
                  final isItemLoading =
                      _loadingActionFriendId != null &&
                      _loadingActionFriendId == friendId;

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 12,
                          thickness: 0.6,
                          color: Colors.grey.shade300,
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF0B4F4A),
                            child: Text(
                              friendName.isNotEmpty
                                  ? friendName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        friendName,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF263238),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: itemExpired
                                            ? const Color(0xFFFFCDD2)
                                            : const Color(0xFFFFE0B2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        itemExpired
                                            ? 'Expired'
                                            : (minLeft != null && minLeft > 0
                                                  ? '${minLeft}m left'
                                                  : 'Expiring'),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: itemExpired
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFFE65100),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.message != null &&
                                    item.message!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.message!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (friendId != null) ...[
                            const SizedBox(width: 6),
                            if (isItemLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0B4F4A),
                                ),
                              )
                            else ...[
                              InkWell(
                                onTap:
                                    (_isExtendingPermissions ||
                                        _isDismissingPermissions)
                                    ? null
                                    : () => _executeLocationSharingAction(
                                        isRenew: true,
                                        userIds: friendId,
                                        individualFriendId: friendId,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B4F4A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Renew',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap:
                                    (_isExtendingPermissions ||
                                        _isDismissingPermissions)
                                    ? null
                                    : () => _executeLocationSharingAction(
                                        isRenew: false,
                                        userIds: friendId,
                                        individualFriendId: friendId,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFD32F2F),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Dismiss',
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            isExpired
                ? 'Your 24 hours location sharing has ended. Renew to continue sharing for the next 24 hours mins, or dismiss to disable.'
                : 'Extend to continue sharing with your assigned contacts for 24 hours dismiss to turn off sharing for all, or manage manually.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (count > 1) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed:
                          (_isExtendingPermissions || _isDismissingPermissions)
                          ? null
                          : () => _executeLocationSharingAction(
                              isRenew: true,
                              isAll: true,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4F4A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child:
                          _isExtendingPermissions &&
                              _loadingActionFriendId == null
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isExpired ? 'RENEW ALL' : 'EXTEND ALL',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed:
                          (_isExtendingPermissions || _isDismissingPermissions)
                          ? null
                          : () => _executeLocationSharingAction(
                              isRenew: false,
                              isAll: true,
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child:
                          _isDismissingPermissions &&
                              _loadingActionFriendId == null
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFD32F2F),
                              ),
                            )
                          : const Text(
                              'DISMISS ALL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: (_isExtendingPermissions || _isDismissingPermissions)
                  ? null
                  : () => _handleManageManually(),
              icon: const Icon(Icons.tune, size: 15, color: Color(0xFF0B4F4A)),
              label: const Text(
                'MANAGE MANUALLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B4F4A),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0B4F4A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionBottomSheet({
    List<SystemAlertItem> items = const [],
    LocationPermissionAlert? locAlert,
  }) {
    final allItems = <SystemAlertItem>[];
    if (items.isNotEmpty) {
      allItems.addAll(items);
    } else if (locAlert != null) {
      allItems.add(
        SystemAlertItem(
          friendId: locAlert.friendId,
          message: locAlert.message,
          friendName: locAlert.friendName,
          minutesRemaining: locAlert.minutesRemaining,
          isExpiring: locAlert.isExpiring,
          isExpired: locAlert.isExpired,
          canRenew: locAlert.canRenew,
        ),
      );
    }

    allItems.removeWhere(
      (item) =>
          item.friendId != null &&
          _locallyHandledFriendIds.contains(item.friendId),
    );

    if (allItems.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isExpired =
                allItems.any((item) => item.isExpired == true) ||
                (locAlert?.isExpired == true);
            final count = allItems.length;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? const Color(0xFFFFCDD2)
                                : const Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isExpired
                                ? Icons.error_outline
                                : Icons.warning_amber_rounded,
                            color: isExpired
                                ? const Color(0xFFC62828)
                                : const Color(0xFFE65100),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isExpired
                                    ? (count > 1
                                          ? 'Permissions Expired ($count)'
                                          : 'Permission Expired')
                                    : (count > 1
                                          ? 'System Alerts ($count)'
                                          : 'System Alert'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isExpired
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFFE65100),
                                ),
                              ),
                              Text(
                                count > 1
                                    ? '$count Contacts Affected'
                                    : 'Location Permissions Expiry',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Scrollable list of items
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...allItems.map((item) {
                              final itemExpired = item.isExpired == true;
                              final friendName = item.friendName ?? 'Contact';
                              final friendId = item.friendId;
                              final minLeft = item.minutesRemaining;
                              final isItemLoading =
                                  _loadingActionFriendId != null &&
                                  _loadingActionFriendId == friendId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: itemExpired
                                      ? const Color(0xFFFFEBEE)
                                      : const Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: itemExpired
                                        ? const Color(0xFFEF9A9A)
                                        : const Color(0xFFFFCC80),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: const Color(
                                            0xFF0B4F4A,
                                          ),
                                          child: Text(
                                            friendName.isNotEmpty
                                                ? friendName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            friendName,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF263238),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: itemExpired
                                                ? const Color(0xFFFFCDD2)
                                                : const Color(0xFFFFE0B2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            itemExpired
                                                ? 'Expired'
                                                : (minLeft != null &&
                                                          minLeft > 0
                                                      ? '${minLeft}m left'
                                                      : 'Expiring'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: itemExpired
                                                  ? const Color(0xFFC62828)
                                                  : const Color(0xFFE65100),
                                            ),
                                          ),
                                        ),
                                        if (friendId != null) ...[
                                          const SizedBox(width: 8),
                                          if (isItemLoading)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF0B4F4A),
                                              ),
                                            )
                                          else ...[
                                            InkWell(
                                              onTap:
                                                  (_isExtendingPermissions ||
                                                      _isDismissingPermissions)
                                                  ? null
                                                  : () => _executeLocationSharingAction(
                                                      isRenew: true,
                                                      userIds: friendId,
                                                      individualFriendId:
                                                          friendId,
                                                      updateSheetState:
                                                          setSheetState,
                                                      onSuccess: () {
                                                        setSheetState(() {
                                                          allItems.removeWhere(
                                                            (it) =>
                                                                it.friendId ==
                                                                friendId,
                                                          );
                                                        });
                                                        if (allItems.isEmpty &&
                                                            sheetContext
                                                                .mounted) {
                                                          Navigator.of(
                                                            sheetContext,
                                                          ).pop();
                                                        }
                                                      },
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF0B4F4A,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Renew',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap:
                                                  (_isExtendingPermissions ||
                                                      _isDismissingPermissions)
                                                  ? null
                                                  : () => _executeLocationSharingAction(
                                                      isRenew: false,
                                                      userIds: friendId,
                                                      individualFriendId:
                                                          friendId,
                                                      updateSheetState:
                                                          setSheetState,
                                                      onSuccess: () {
                                                        setSheetState(() {
                                                          allItems.removeWhere(
                                                            (it) =>
                                                                it.friendId ==
                                                                friendId,
                                                          );
                                                        });
                                                        if (allItems.isEmpty &&
                                                            sheetContext
                                                                .mounted) {
                                                          Navigator.of(
                                                            sheetContext,
                                                          ).pop();
                                                        }
                                                      },
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFEBEE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFD32F2F,
                                                    ),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Dismiss',
                                                  style: TextStyle(
                                                    color: Color(0xFFD32F2F),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                    if (item.message != null &&
                                        item.message!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.message!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF37474F),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            Text(
                              isExpired
                                  ? 'Choose an action to handle your location sharing:\n'
                                        '• RENEW: Renew expiring location access for the next 24 hours.\n'
                                        '• DISMISS: Automatically disable location sharing for all.\n'
                                        '• MANAGE MANUALLY: Review and toggle individual contacts.'
                                  : 'Choose an action to handle your location sharing:\n'
                                        '• EXTEND: Automatically extend location permission for assigned contacts for 24 hours.\n'
                                        '• DISMISS: Automatically disable location sharing for all.\n'
                                        '• MANAGE MANUALLY: Review and toggle individual contacts on the permissions screen.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (count > 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed:
                                    (_isExtendingPermissions ||
                                        _isDismissingPermissions)
                                    ? null
                                    : () async {
                                        await _executeLocationSharingAction(
                                          isRenew: true,
                                          isAll: true,
                                          dialogContext: sheetContext,
                                          updateSheetState: setSheetState,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B4F4A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child:
                                    _isExtendingPermissions &&
                                        _loadingActionFriendId == null
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isExpired ? 'RENEW ALL' : 'EXTEND ALL',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed:
                                    (_isExtendingPermissions ||
                                        _isDismissingPermissions)
                                    ? null
                                    : () async {
                                        await _executeLocationSharingAction(
                                          isRenew: false,
                                          isAll: true,
                                          dialogContext: sheetContext,
                                          updateSheetState: setSheetState,
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD32F2F),
                                  side: const BorderSide(
                                    color: Color(0xFFD32F2F),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child:
                                    _isDismissingPermissions &&
                                        _loadingActionFriendId == null
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFD32F2F),
                                        ),
                                      )
                                    : const Text(
                                        'DISMISS ALL',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed:
                            (_isExtendingPermissions ||
                                _isDismissingPermissions)
                            ? null
                            : () => _handleManageManually(
                                dialogContext: sheetContext,
                              ),
                        icon: const Icon(
                          Icons.tune,
                          size: 16,
                          color: Color(0xFF0B4F4A),
                        ),
                        label: const Text(
                          'MANAGE MANUALLY',
                          style: TextStyle(
                            color: Color(0xFF0B4F4A),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0B4F4A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimelineTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.isNegative || diff.inSeconds < 60) return '(just now)';
    if (diff.inMinutes < 60) return '(${diff.inMinutes}m ago)';
    if (diff.inHours < 24) return '(${diff.inHours}h ago)';
    if (diff.inDays == 1) return '(yesterday)';
    return '(${diff.inDays}d ago)';
  }

  bool _isHindi = false;
  bool _isSosLoading = false;

  void _sendHelpAlertToMembers() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            _isHindi ? 'मदद की चेतावनी भेजें' : 'Send Help Alert',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _isHindi
                ? 'क्या आप सुनिश्चित हैं कि आप अपने सभी जुड़े हुए सदस्यों को यह संदेश भेजना चाहते हैं कि आपको मदद की आवश्यकता है?'
                : 'Are you sure you want to notify all connected members that you need help?',
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _isHindi ? 'रद्द करें' : 'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: _triggerEmergencySos,
              child: Text(
                _isHindi ? 'हाँ, भेजें' : 'Yes, Send',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerEmergencySos() async {
    Navigator.pop(context);

    setState(() {
      _isSosLoading = true;
    });

    showErrorSnackBar(
      _isHindi
          ? 'आपातकालीन एसओएस भेजा जा रहा है...'
          : 'Sending Emergency SOS alert...',
      context,
    );

    try {
      Position? position;

      // 1. Check and request permission if needed
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (_) {}

      // 2. Fetch fresh high-accuracy position (uses Google Fused Location,
      // giving sufficient time for the user to tap "Turn on" on the system dialog)
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        // Fallback A: Cached position
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}

        // Fallback B: Quick low-accuracy (Cell/WiFi)
        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (_) {}
        }
      }

      // If location is still unavailable, notify user but do NOT block SOS (Emergency Fail-safe)
      if (position == null && mounted) {
        showErrorSnackBar(
          _isHindi
              ? 'स्थान उपलब्ध नहीं है, बिना जीपीएस के आपातकालीन एसओएस भेजा जा रहा है...'
              : 'GPS unavailable. Sending Emergency SOS without location...',
          context,
        );
      }

      final body = TriggerSosBodyModel(
        latitude: position?.latitude,
        longitude: position?.longitude,
        triggerType: "APP_BUTTON",
        batteryPercentage: 70,
      );

      final response = await ref.read(authServiceProvider).triggerSosData(body);

      if (!mounted) return;

      if (response.success == true) {
        showSuccessSnackBar(
          response.message ??
              (_isHindi
                  ? 'आपातकालीन एसओएस अलर्ट सफलतापूर्वक भेजा गया!'
                  : 'Emergency SOS alert triggered successfully!'),
          context,
        );
      } else {
        showErrorSnackBar(
          response.message ??
              (_isHindi
                  ? 'एसओएस भेजने में विफल रहा।'
                  : 'Failed to trigger SOS alert.'),
          context,
        );
      }
    } catch (e) {
      log(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSosLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box("userdata");
    var role = box.get("role");
    final getdashBordData = ref.watch(getDashbordProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      drawer: const AppDrawer(isHindi: false),
      // AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4F4A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'My Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(isHindi: _isHindi),
                ),
              );
            },
            child: Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingScreen(isHindi: false),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                child: Tooltip(
                  message: 'Profile',
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFFFD54F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Hive.isBoxOpen('userdata')
                        ? ValueListenableBuilder<Box>(
                            valueListenable: Hive.box(
                              'userdata',
                            ).listenable(keys: ['profileImage', 'name']),
                            builder: (context, box, _) {
                              final img = box.get('profileImage')?.toString();
                              final name =
                                  box.get('name')?.toString().trim() ?? '';
                              final initial = name.isEmpty
                                  ? '?'
                                  : name[0].toUpperCase();

                              if (img != null && img.trim().isNotEmpty) {
                                return CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFF0F3D38),
                                  backgroundImage: NetworkImage(img),
                                );
                              }
                              return CircleAvatar(
                                radius: 15,
                                backgroundColor: const Color(0xFF0F3D38),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            },
                          )
                        : const CircleAvatar(
                            radius: 15,
                            backgroundColor: Color(0xFF0F3D38),
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Body
      body: RefreshIndicator(
        color: const Color(0xFF0B4F4A),
        onRefresh: () async {
          _actionTakenInSession = false;
          try {
            final box = Hive.isBoxOpen('userdata')
                ? Hive.box('userdata')
                : null;
            await box?.delete('location_permission_alert_dismissed_until');
          } catch (_) {}
          ref.invalidate(getDashbordProvider);
          await ref.read(getDashbordProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (role != "company")
                Container(
                  constraints: const BoxConstraints(minHeight: 58),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  color: const Color(0xFF0B4F4A),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddNetworkSearchScreen(),
                              ),
                            );
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Add network...',
                            hintStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 18,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            contentPadding: const EdgeInsets.only(bottom: 4),
                          ),
                        ),
                      ),
                      // const SizedBox(width: 12),
                      // InkWell(
                      //   onTap: () {},
                      //   child: const Icon(
                      //     Icons.tune,
                      //     color: Colors.white,
                      //     size: 20,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              getdashBordData.when(
                data: (dashboardModel) {
                  final alertsAndTasks = dashboardModel.data?.alertsAndTasks;
                  final systemAlertItems =
                      alertsAndTasks?.systemAlertItems ?? [];
                  final locAlert = alertsAndTasks?.locationPermissionAlert;

                  final hasSystemAlertItems = systemAlertItems.any(
                    (item) =>
                        item.isExpiring == true ||
                        item.isExpired == true ||
                        item.canRenew == true,
                  );
                  final hasLocAlert =
                      locAlert != null &&
                      (locAlert.isExpiring == true ||
                          locAlert.isExpired == true ||
                          locAlert.canRenew == true);
                  final hasCountAlert =
                      (alertsAndTasks?.systemAlerts ?? 0) > 0 &&
                      (systemAlertItems.isNotEmpty || locAlert != null);

                  final hasBackendAlert =
                      hasSystemAlertItems || hasLocAlert || hasCountAlert;
                  final shouldShowAlert =
                      hasBackendAlert && !_isAlertLocallyMuted();

                  final recentTimeline = dashboardModel.data?.recentTimeline;
                  final timelineItems = recentTimeline?.items ?? [];
                  final networkOverview = dashboardModel.data?.networkOverview;
                  final performance = dashboardModel.data?.performanceInsights;
                  final byDayList = performance?.byDay ?? [];

                  final connectionCount =
                      alertsAndTasks?.connectionRequests ?? 0;
                  final systemCount = alertsAndTasks?.systemAlerts ?? 0;
                  final calculatedTotal = connectionCount + systemCount;
                  final rawTotal = alertsAndTasks?.total ?? 0;
                  final totalAlerts = rawTotal > calculatedTotal
                      ? rawTotal
                      : calculatedTotal;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        if (shouldShowAlert)
                          _buildLocationPermissionExpiryBanner(
                            items: systemAlertItems,
                            locAlert: locAlert,
                          ),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // =====================================================
                              // ALERTS & TASKS
                              // =====================================================
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Alerts & Tasks',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Center(
                                        child: Text(
                                          '$totalAlerts',
                                          style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffE5F0EF),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.people_outline,
                                              size: 17,
                                              color: Color(0xff0B4F4A),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Connection',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Requests (${alertsAndTasks?.connectionRequests ?? 0})',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      InkWell(
                                        onTap: shouldShowAlert
                                            ? () {
                                                _showLocationPermissionBottomSheet(
                                                  items: systemAlertItems,
                                                  locAlert: locAlert,
                                                );
                                              }
                                            : null,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: shouldShowAlert
                                                ? const Color(0xFFFFECC8)
                                                : const Color(0xffE5F0EF),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: shouldShowAlert
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFFFFA000,
                                                    ),
                                                    width: 1,
                                                  )
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                size: 17,
                                                color: shouldShowAlert
                                                    ? const Color(0xFFE65100)
                                                    : const Color(0xff0B4F4A),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'System',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Alerts (${alertsAndTasks?.systemAlerts ?? 0})',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (shouldShowAlert)
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  margin: const EdgeInsets.only(
                                                    right: 2,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFE65100,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // =====================================================
                              // RECENT TIMELINE
                              // =====================================================
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recent Timeline',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (timelineItems.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'No recent activity',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        ...timelineItems.take(3).map((item) {
                                          final timeStr = _formatTimelineTime(
                                            item.occurredAt,
                                          );
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  child: Icon(
                                                    Icons.circle,
                                                    size: 6,
                                                    color: Color(0xff0B4F4A),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item.title != null &&
                                                            item
                                                                .title!
                                                                .isNotEmpty
                                                        ? '${item.title} $timeStr'
                                                              .trim()
                                                        : 'Activity $timeStr'
                                                              .trim(),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // =====================================================
                              // NETWORK OVERVIEW
                              // =====================================================
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Network Overview',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${networkOverview?.totalConnections ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 27,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Total Connections: ${networkOverview?.totalConnections ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF555555),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 32,
                                        width: 120,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 0,
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    Colors.brown.shade300,
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            if ((networkOverview
                                                        ?.totalConnections ??
                                                    0) >
                                                1)
                                              Positioned(
                                                left: 18,
                                                child: CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      Colors.grey.shade500,
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            if ((networkOverview
                                                        ?.totalConnections ??
                                                    0) >
                                                2)
                                              Positioned(
                                                left: 36,
                                                child: CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      Colors.brown.shade400,
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            Positioned(
                                              left:
                                                  (networkOverview
                                                              ?.totalConnections ??
                                                          0) >
                                                      2
                                                  ? 54
                                                  : ((networkOverview
                                                                    ?.totalConnections ??
                                                                0) >
                                                            1
                                                        ? 36
                                                        : 18),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xff0B4F4A),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '+${networkOverview?.totalConnections ?? 0}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (networkOverview?.acceptedFriends !=
                                              null ||
                                          networkOverview?.sentRequests != null)
                                        Text(
                                          'Friends: ${networkOverview?.acceptedFriends ?? 0} | Sent: ${networkOverview?.sentRequests ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF65716D),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // =====================================================
                              // PERFORMANCE INSIGHTS
                              // =====================================================
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Performance Insights',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total: ${performance?.totalConnections ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF65716D),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Builder(
                                        builder: (context) {
                                          final List<ByDay> days =
                                              byDayList.isNotEmpty
                                              ? byDayList
                                              : [
                                                  ByDay(day: 'Mo', count: 0),
                                                  ByDay(day: 'Tu', count: 0),
                                                  ByDay(day: 'We', count: 0),
                                                  ByDay(day: 'Th', count: 0),
                                                  ByDay(day: 'Fr', count: 0),
                                                ];
                                          final int maxCount = days.fold<int>(
                                            0,
                                            (prev, e) => (e.count ?? 0) > prev
                                                ? (e.count ?? 0)
                                                : prev,
                                          );

                                          return Column(
                                            children: [
                                              SizedBox(
                                                height: 65,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: days.map((dayItem) {
                                                    final count =
                                                        dayItem.count ?? 0;
                                                    final double barHeight =
                                                        maxCount > 0
                                                        ? ((count / maxCount) *
                                                                  50) +
                                                              10
                                                        : 8.0;
                                                    return Tooltip(
                                                      message:
                                                          '${dayItem.day ?? ''}: $count',
                                                      child: Container(
                                                        width: 12,
                                                        height: barHeight,
                                                        decoration: BoxDecoration(
                                                          color: count > 0
                                                              ? const Color(
                                                                  0xff0B4F4A,
                                                                )
                                                              : const Color(
                                                                  0xff3B8C84,
                                                                ).withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                          borderRadius:
                                                              const BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      3,
                                                                    ),
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: days.map((dayItem) {
                                                  return Text(
                                                    dayItem.day ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  );
                },
                error: (error, stackTrace) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B4F4A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              ref.invalidate(getDashbordProvider);
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height / 2,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0B4F4A)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSosLoading ? null : _sendHelpAlertToMembers,
        backgroundColor: Colors.red.shade700,
        icon: _isSosLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.sos, color: Colors.white, size: 22.sp),
        label: Text(
          _isSosLoading
              ? (_isHindi ? 'भेज रहे हैं...' : 'Sending...')
              : (_isHindi ? 'मदद चाहिए' : 'Need Help'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
