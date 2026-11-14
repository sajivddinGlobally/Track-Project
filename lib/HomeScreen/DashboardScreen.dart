import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const double _minDistanceMeters = 15;
  static const Duration _minInterval = Duration(seconds: 5);
  bool _askedAlwaysPermission = false;
  bool _isStarting = false;
  Position? _lastSent;
  DateTime? _lastSentAt;
  io.Socket? _ageOutSocket;
  bool _isExtendingPermissions = false;
  bool _isDismissingPermissions = false;
  bool _actionTakenInSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureHiveOpen();
    _checkPermissions();
    _checkAgeOutGate();
    _initAgeOutSocket();
    _startLocationUpdates();
    _syncFcmTokenIfAvailable();
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
        // 'https://loveable-backend-5qi0.onrender.com',
        'https://api.tracklovedones.com',
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

  Future<void> _syncFcmTokenIfAvailable() async {
    try {
      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');
      final fcmToken = box.get('fcm_token')?.toString();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        FcmNotificationService.syncFcmToken(
          fcmToken,
          authService: ref.read(authServiceProvider),
        );
      }
    } catch (e) {
      log('[FCM] Error checking fcm token: $e');
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
      // Fires only after the user moves at least 15 metres.
      _locationSub = Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).listen(_sendLocation);
      // Send the starting point once, without waiting for movement.
      _sendLocation(await Geolocator.getCurrentPosition());
    } catch (e) {
      debugPrint('Location stream failed: $e');
    }
  }

  LocationSettings _buildLocationSettings() {
    const accuracy = LocationAccuracy.high;
    const distanceFilter = 15; // keep in sync with _minDistanceMeters
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        // Foreground service keeps updates alive when the app is in background.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Track Loved',
          notificationText: 'Sharing your location with your trusted network',
          notificationChannelName: 'Location Service',
          enableWakeLock: false,
          setOngoing: false,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
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
      if (moved < _minDistanceMeters || elapsed < _minInterval) {
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

  Future<void> _handleExtendPermissions({BuildContext? dialogContext}) async {
    if (_isExtendingPermissions || _isDismissingPermissions) return;
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
    setState(() => _isExtendingPermissions = true);
    try {
      final service = ref.read(authServiceProvider);
      // Call backend dynamic action API to renew location access for next 24 hours
      final res = await service.locationSharingActionData(
        locationAccessRenew: true,
      );

      await _recordAlertActionTaken();
      ref.invalidate(getDashbordProvider);

      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message ??
                  'Expiring location access was renewed for the next 24 hours.',
            ),
            backgroundColor: const Color(0xFF0B4F4A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      log('[Dashboard] Error extending permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extend permissions: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtendingPermissions = false);
    }
  }

  Future<void> _handleDismissPermissions({BuildContext? dialogContext}) async {
    if (_isExtendingPermissions || _isDismissingPermissions) return;
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
    setState(() => _isDismissingPermissions = true);
    try {
      final service = ref.read(authServiceProvider);
      // Call backend dynamic action API to disable location access for all friends
      final res = await service.locationSharingActionData(
        locationAccessDisable: true,
      );

      await _recordAlertActionTaken();
      ref.invalidate(getDashbordProvider);

      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message ?? 'Location sharing was disabled for all friends.',
            ),
            backgroundColor: Colors.black87,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      log('[Dashboard] Error dismissing permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable location sharing: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDismissingPermissions = false);
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
          message: locAlert.message,
          friendName: locAlert.friendName,
          minutesRemaining: locAlert.minutesRemaining,
          isExpiring: locAlert.isExpiring,
          isExpired: locAlert.isExpired,
          canRenew: locAlert.canRenew,
        ),
      );
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

          // If multiple items, list each contact cleanly
          if (count > 1) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
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
                  final minLeft = item.minutesRemaining;

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 12,
                          thickness: 0.6,
                          color: Colors.grey.shade300,
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  ),
                                ],
                              ],
                            ),
                          ),
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
                ? 'Your 24-hour location sharing has ended. Renew to continue sharing for the next 24 hours, or dismiss to disable.'
                : 'Extend to continue sharing with your assigned contacts for 24 hours, dismiss to turn off sharing for all, or manage manually.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed:
                        (_isExtendingPermissions || _isDismissingPermissions)
                        ? null
                        : () => _handleExtendPermissions(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4F4A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: _isExtendingPermissions
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isExpired
                                ? (count > 1 ? 'RENEW ALL' : 'RENEW')
                                : (count > 1 ? 'EXTEND ALL' : 'EXTEND'),
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
                        : () => _handleDismissPermissions(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: _isDismissingPermissions
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD32F2F),
                            ),
                          )
                        : Text(
                            count > 1 ? 'DISMISS ALL' : 'DISMISS',
                            style: const TextStyle(
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
          message: locAlert.message,
          friendName: locAlert.friendName,
          minutesRemaining: locAlert.minutesRemaining,
          isExpiring: locAlert.isExpiring,
          isExpired: locAlert.isExpired,
          canRenew: locAlert.canRenew,
        ),
      );
    }

    final isExpired =
        allItems.any((item) => item.isExpired == true) ||
        (locAlert?.isExpired == true);
    final count = allItems.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                              final minLeft = item.minutesRemaining;

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
                                      setSheetState(() {});
                                      await _handleExtendPermissions(
                                        dialogContext: sheetContext,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B4F4A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isExtendingPermissions
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isExpired
                                          ? (count > 1 ? 'RENEW ALL' : 'RENEW')
                                          : (count > 1
                                                ? 'EXTEND ALL'
                                                : 'EXTEND'),
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
                                      setSheetState(() {});
                                      await _handleDismissPermissions(
                                        dialogContext: sheetContext,
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
                              child: _isDismissingPermissions
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFD32F2F),
                                      ),
                                    )
                                  : Text(
                                      count > 1 ? 'DISMISS ALL' : 'DISMISS',
                                      style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
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
                MaterialPageRoute(builder: (context) => NotificationScreen()),
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
                                          '${alertsAndTasks?.total ?? 0}',
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
    );
  }
}
