import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/complanyProfile/companyProfileScreen.dart';

class DynamicDashboardScreen extends ConsumerStatefulWidget {
  const DynamicDashboardScreen({super.key});

  @override
  ConsumerState<DynamicDashboardScreen> createState() =>
      _DynamicDashboardScreenState();
}

class _DynamicDashboardScreenState
    extends ConsumerState<DynamicDashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<Position>? _locationSub;
  static const double _minDistanceMeters = 15;
  static const Duration _minInterval = Duration(seconds: 5);
  bool _askedAlwaysPermission = false;
  bool _isStarting = false;
  Position? _lastSent;
  DateTime? _lastSentAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _startLocationUpdates();
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
          enableWakeLock: true,
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
        debugPrint(
          '[Location] skipped: moved ${moved.toStringAsFixed(1)} m, '
          '${elapsed.inSeconds}s since last send',
        );
        return;
      }
    }
    _lastSent = position;
    debugPrint('[Location] sending ${position.latitude}, ${position.longitude}');
    _lastSentAt = DateTime.now();
    try {
      await ref
          .read(authServiceProvider)
          .updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      debugPrint('[Location] sent OK');
    } catch (e) {
      debugPrint('[Location] update FAILED: $e');
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.tune, color: Colors.white, size: 20),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: '',
            onPressed: () {},
          ),
        ],
      ),

      // Body
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 58,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF0B4F4A),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                        contentPadding: const EdgeInsets.only(bottom: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyProfileScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      // =====================================================
                      // ALERTS & TASKS
                      // =====================================================
                      Expanded(
                        child: Container(
                          height: 175,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alerts & Tasks Card',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Center(
                                child: Text(
                                  '12',
                                  style: TextStyle(
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
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 17,
                                      color: Color(0xff0B4F4A),
                                    ),
                                    SizedBox(width: 5),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Connection',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          'Requests (5)',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xffE5F0EF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 17,
                                      color: Color(0xff0B4F4A),
                                    ),
                                    SizedBox(width: 5),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'System',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          'Alerts (7)',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
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
                          height: 175,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Timeline',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: Color(0xff0B4F4A),
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'New request from Sarah J. (just now)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: Color(0xff0B4F4A),
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Address updated (3 hours ago)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: Color(0xff0B4F4A),
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Address updated (3 hours ago)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // =====================================================
                      // NETWORK OVERVIEW
                      // =====================================================
                      Expanded(
                        child: Container(
                          height: 175,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Network',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'Overview Card',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '548',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Total Connections: 548',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 32,
                                width: 115,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.brown.shade300,
                                        child: const Icon(
                                          Icons.person,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 17,
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.grey.shade500,
                                        child: const Icon(
                                          Icons.person,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 34,
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.brown.shade400,
                                        child: const Icon(
                                          Icons.person,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 51,
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.grey.shade600,
                                        child: const Icon(
                                          Icons.person,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 68,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: Color(0xff0B4F4A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '+34',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // =====================================================
                      // PERFORMANCE
                      // =====================================================
                      Expanded(
                        child: Container(
                          height: 175,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Performance',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'Insights Card',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 35,
                                      color: const Color(0xff3B8C84),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 60,
                                      color: const Color(0xff3B8C84),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 45,
                                      color: const Color(0xff3B8C84),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 28,
                                      color: const Color(0xff3B8C84),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 52,
                                      color: const Color(0xff3B8C84),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text('Mo', style: TextStyle(fontSize: 11)),
                                  Text('Tu', style: TextStyle(fontSize: 11)),
                                  Text('We', style: TextStyle(fontSize: 11)),
                                  Text('Th', style: TextStyle(fontSize: 11)),
                                  Text('Fr', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
