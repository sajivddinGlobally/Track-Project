import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';
import 'package:track_loved/core/Utils/AddressText.dart';
import 'package:track_loved/core/Utils/showMessage.dart';
import 'package:url_launcher/url_launcher.dart';

// const String kSocketBaseUrl = 'https://api.tracklovedones.com';
const String kSocketBaseUrl = 'https://loveable-backend-5qi0.onrender.com';

class LiveLocationMapScreen extends ConsumerStatefulWidget {
  final LocationSharingUser user;
  final bool isHindi;

  const LiveLocationMapScreen({
    super.key,
    required this.user,
    this.isHindi = false,
  });

  @override
  ConsumerState<LiveLocationMapScreen> createState() =>
      _LiveLocationMapScreenState();
}

class _LiveLocationMapScreenState extends ConsumerState<LiveLocationMapScreen> {
  final MapController _mapController = MapController();
  io.Socket? _socket;
  StreamSubscription<Position>? _myLocationSub;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  LatLng? _position; // Friend's location
  LatLng? _myPosition; // My current location
  DateTime? _updatedAt;
  bool _connected = false;
  bool _closing = false;
  bool _disposed = false;
  String? _error;

  // Directions and Route Data
  List<LatLng> _routePoints = [];
  String? _distanceText;
  String? _durationText;
  DateTime? _lastRouteFetchAt;

  bool get _hi => widget.isHindi;

  @override
  void initState() {
    super.initState();
    final lat = widget.user.latitude;
    final lng = widget.user.longitude;
    if (lat != null && lng != null) _position = LatLng(lat, lng);
    _updatedAt = widget.user.updatedAt;

    _startMyLocationTracking();
    _connect();

    if (_position == null && widget.user.userId != null) {
      _fetchFriendLocation(widget.user.userId!);
    }
  }

  Future<void> _startMyLocationTracking() async {
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final initPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          ).catchError((_) async => (await Geolocator.getLastKnownPosition())!);

          if (!_disposed && mounted) {
            setState(() {
              _myPosition = LatLng(initPos.latitude, initPos.longitude);
            });
            _updateRouteIfNeeded();
          }

          _myLocationSub =
              Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 5,
                ),
              ).listen((pos) {
                if (_disposed || !mounted) return;
                setState(() {
                  _myPosition = LatLng(pos.latitude, pos.longitude);
                });
                _updateRouteIfNeeded();
              });
        }
      }
    } catch (e) {
      log('[LiveLocationMap] My location tracking error: $e');
    }
  }

  Future<void> _fetchFriendLocation(String friendId) async {
    try {
      final res = await ref.read(authServiceProvider).getLocation(id: friendId);
      if (_disposed || !mounted) return;
      if (res.success == true && res.data?.location?.coordinates != null) {
        final coords = res.data!.location!.coordinates;
        if (coords.length >= 2) {
          final lat = coords[1];
          final lng = coords[0];
          _moveTo(LatLng(lat, lng), res.data?.updatedAt);
        }
      }
    } catch (e) {
      log('[LiveLocationMap] Fetch location error: $e');
    }
  }

  Future<void> _connect() async {
    final friendId = widget.user.userId;
    if (friendId == null) return;

    final box = Hive.isBoxOpen('userdata')
        ? Hive.box('userdata')
        : await Hive.openBox('userdata');
    final token = box.get('token')?.toString() ?? '';
    if (!mounted) return;

    final socket = io.io(kSocketBaseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
    });
    _socket = socket;
    log('[Socket] connecting to $kSocketBaseUrl for friend $friendId');

    socket.on('friend_location_update', (dynamic data) {
      log('[Socket] friend_location_update: $data');
      if (data is! Map || data['userId']?.toString() != friendId) return;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      _moveTo(
        LatLng(lat, lng),
        DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
      );
    });

    void subscribe() {
      socket.emitWithAck(
        'subscribe_friend_location',
        {'friendId': friendId},
        ack: (dynamic response) {
          log('[Socket] subscribe ack: $response');
          if (_disposed || !mounted || response is! Map) return;
          if (response['success'] != true) {
            setState(() => _error = response['message']?.toString());
            return;
          }
          final location = (response['data'] as Map?)?['location'];
          final coords = location is Map ? location['coordinates'] : null;
          if (coords is List && coords.length >= 2) {
            _moveTo(
              LatLng(
                (coords[1] as num).toDouble(),
                (coords[0] as num).toDouble(),
              ),
              _updatedAt,
            );
          }
        },
      );
    }

    socket.on('location_sharing_updated', (dynamic data) {
      log('[Socket] location_sharing_updated: $data');
      if (data is! Map || data['locationOwnerId']?.toString() != friendId) {
        return;
      }
      if (data['sharingEnabled'] == false) {
        _onSharingStopped(data['message']?.toString());
      } else if (data['sharingEnabled'] == true) {
        subscribe();
      }
    });

    socket.onConnect((_) {
      log('[Socket] CONNECTED id=${socket.id}');
      if (_disposed || !mounted) return;
      setState(() {
        _connected = true;
        _error = null;
      });
      subscribe();
    });

    socket.onDisconnect((reason) {
      log('[Socket] DISCONNECTED: $reason');
      if (!_disposed && mounted) setState(() => _connected = false);
    });

    socket.onConnectError((e) {
      log('[Socket] CONNECT ERROR: $e');
      if (!_disposed && mounted) {
        setState(() {
          _connected = false;
          _error = _hi ? 'लाइव कनेक्शन नहीं हो सका' : 'Live connection failed';
        });
      }
    });

    socket.connect();
  }

  void _onSharingStopped(String? message) {
    if (_disposed || !mounted || _closing) return;
    _closing = true;
    setState(() => _position = null);
    showErrorSnackBar(
      message ??
          (_hi
              ? 'स्थान साझा करना बंद कर दिया गया है।'
              : 'Location sharing has been turned off.'),
    );
    Navigator.of(context).maybePop();
  }

  void _moveTo(LatLng point, DateTime? updatedAt) {
    if (_disposed || !mounted) return;
    setState(() {
      _position = point;
      _updatedAt = updatedAt ?? DateTime.now();
    });
    _updateRouteIfNeeded();
  }

  // Fetch road directions between My Position and Friend's Position
  Future<void> _updateRouteIfNeeded() async {
    final myPos = _myPosition;
    final friendPos = _position;
    if (myPos == null || friendPos == null) return;

    final now = DateTime.now();
    if (_lastRouteFetchAt != null &&
        now.difference(_lastRouteFetchAt!).inSeconds < 4) {
      return;
    }
    _lastRouteFetchAt = now;

    // Calculate straight-line distance as baseline
    final straightDist = Geolocator.distanceBetween(
      myPos.latitude,
      myPos.longitude,
      friendPos.latitude,
      friendPos.longitude,
    );

    String calcDistText;
    if (straightDist < 1000) {
      calcDistText = '${straightDist.round()} m';
    } else {
      calcDistText = '${(straightDist / 1000).toStringAsFixed(1)} km';
    }
    final approxMinutes = (straightDist / 1000 / 25 * 60).round().clamp(1, 999);
    final calcDurText = '$approxMinutes min';

    // If users are within walking / room distance (< 60 meters),
    // driving car router snaps off-road to distant roads.
    // Connect markers directly with a straight direction line!
    if (straightDist < 60) {
      if (_disposed || !mounted) return;
      setState(() {
        _routePoints = [myPos, friendPos];
        _distanceText = calcDistText;
        _durationText = '1 min';
      });
      return;
    }

    if (_disposed || !mounted) return;
    setState(() {
      if (_routePoints.isEmpty) {
        _routePoints = [myPos, friendPos];
      }
      _distanceText = calcDistText;
      _durationText = calcDurText;
    });

    // Fetch road geometry from OpenStreetMap OSRM Routing
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${myPos.longitude},${myPos.latitude};'
          '${friendPos.longitude},${friendPos.latitude}'
          '?overview=full&geometries=geojson';

      final response = await _dio.get(url);
      if (_disposed || !mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distanceMeters =
              (route['distance'] as num?)?.toDouble() ?? straightDist;
          final double durationSeconds =
              (route['duration'] as num?)?.toDouble() ?? (approxMinutes * 60.0);

          final geometry = route['geometry'];
          if (geometry != null && geometry['coordinates'] is List) {
            final rawCoords = geometry['coordinates'] as List;
            final List<LatLng> points = rawCoords.map<LatLng>((c) {
              return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
            }).toList();

            final String realDist = distanceMeters < 1000
                ? '${distanceMeters.round()} m'
                : '${(distanceMeters / 1000).toStringAsFixed(1)} km';
            final int mins = (durationSeconds / 60).round().clamp(1, 999);
            final String realDur = '$mins min';

            // Anchor route line: starts at myPos, follows road geometry, ends at friendPos
            final List<LatLng> anchoredPoints = [myPos, ...points, friendPos];

            setState(() {
              _routePoints = anchoredPoints;
              _distanceText = realDist;
              _durationText = realDur;
            });
            return;
          }
        }
      }
    } catch (e) {
      log('[OSRM] Route fetch error: $e');
    }

    // Fallback: draw straight direction line connecting both markers directly
    if (!_disposed && mounted) {
      setState(() {
        _routePoints = [myPos, friendPos];
      });
    }
  }

  void _fitBounds() {
    final myPos = _myPosition;
    final friendPos = _position;
    if (myPos == null && friendPos == null) return;

    if (myPos != null && friendPos != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([myPos, friendPos]),
          padding: const EdgeInsets.all(50),
        ),
      );
    } else if (friendPos != null) {
      _mapController.move(friendPos, 16);
    } else if (myPos != null) {
      _mapController.move(myPos, 16);
    }
  }

  void _openInGoogleMaps() {
    final pos = _position;
    if (pos == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pos.latitude},${pos.longitude}',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _disposed = true;
    _myLocationSub?.cancel();
    _socket?.clearListeners();
    _socket?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _timeText(DateTime? d) {
    if (d == null) return _hi ? 'उपलब्ध नहीं' : 'Not available';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.user.name?.trim().isNotEmpty ?? false)
        ? widget.user.name!
        : (_hi ? 'अनाम मित्र' : 'Unknown Friend');
    final friendPos = _position;
    final myPos = _myPosition;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002E29),
        foregroundColor: Colors.white,
        title: Text(name),
        actions: [
          if (friendPos != null)
            IconButton(
              icon: const Icon(Icons.directions, color: Colors.white),
              tooltip: _hi ? 'गूगल मैप्स में खोलें' : 'Open in Google Maps',
              onPressed: _openInGoogleMaps,
            ),
        ],
      ),
      body: friendPos == null && myPos == null
          ? Center(
              child: Text(
                _error ??
                    (_hi ? 'स्थान लोड हो रहा है...' : 'Loading location...'),
                textAlign: TextAlign.center,
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        friendPos ?? myPos ?? const LatLng(20.5937, 78.9629),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.trackloved.app',
                    ),
                    // Road Direction Route Line (Polyline)
                    if (_routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF0288D1),
                            strokeWidth: 5.5,
                            borderColor: Colors.white,
                            borderStrokeWidth: 1.5,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // 1. My Location Marker (Blue Dot with Ring)
                        if (myPos != null)
                          Marker(
                            point: myPos,
                            width: 60,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D47A1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _hi ? 'आप' : 'You',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // 2. Loved One Marker (Avatar Pin)
                        if (friendPos != null)
                          Marker(
                            point: friendPos,
                            width: 70,
                            height: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF002E29),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child:
                                      (widget.user.profileImage != null &&
                                          widget.user.profileImage!.isNotEmpty)
                                      ? ClipOval(
                                          child: Image.network(
                                            widget.user.profileImage!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Floating Action Map Controls (Right Side)
                Positioned(
                  right: 16.w,
                  top: 20.h,
                  child: Column(
                    children: [
                      // Fit Both in View
                      FloatingActionButton.small(
                        heroTag: 'fit_route_btn',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF002E29),
                        onPressed: _fitBounds,
                        child: const Icon(Icons.alt_route),
                      ),
                      SizedBox(height: 10.h),
                      // Recenter on Loved One
                      if (friendPos != null) ...[
                        FloatingActionButton.small(
                          heroTag: 'friend_pos_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade700,
                          onPressed: () => _mapController.move(friendPos, 16),
                          child: const Icon(Icons.person_pin_circle),
                        ),
                        SizedBox(height: 10.h),
                      ],
                      // Recenter on My Location
                      if (myPos != null)
                        FloatingActionButton.small(
                          heroTag: 'my_pos_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          onPressed: () => _mapController.move(myPos, 16),
                          child: const Icon(Icons.my_location),
                        ),
                    ],
                  ),
                ),

                // Bottom Live Summary Card
                if (friendPos != null)
                  Positioned(
                    left: 14.w,
                    right: 14.w,
                    bottom: 20.h,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: EdgeInsets.all(14.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Status and Distance/Time
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10.sp,
                                  color: _connected
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  '${_connected ? (_hi ? 'लाइव सक्रिय' : 'Live Active') : (_hi ? 'ऑफलाइन' : 'Offline')}'
                                  ' • ${_timeText(_updatedAt)}',
                                  style: TextStyle(
                                    color: _connected
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_distanceText != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.directions_car,
                                          size: 13.sp,
                                          color: const Color(0xFF0D47A1),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '${_durationText ?? ''} • ${_distanceText!}',
                                          style: TextStyle(
                                            color: const Color(0xFF0D47A1),
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            // Reverse-Geocoded Live Address
                            AddressText(
                              latitude: friendPos.latitude,
                              longitude: friendPos.longitude,
                              isHindi: _hi,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Button to Open Turn-by-Turn in Google Maps
                            SizedBox(
                              width: double.infinity,
                              height: 44.h,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF002E29),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.directions,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  _hi
                                      ? 'गूगल मैप्स में नेविगेट करें'
                                      : 'Navigate in Google Maps',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _openInGoogleMaps,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
