import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';
import 'package:track_loved/core/Utils/AddressText.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

// Socket server root (no /api/v1 path).
const String kSocketBaseUrl = 'https://loveable-backend-5qi0.onrender.com';

class LiveLocationMapScreen extends StatefulWidget {
  final LocationSharingUser user;
  final bool isHindi;

  const LiveLocationMapScreen({
    super.key,
    required this.user,
    this.isHindi = false,
  });

  @override
  State<LiveLocationMapScreen> createState() => _LiveLocationMapScreenState();
}

class _LiveLocationMapScreenState extends State<LiveLocationMapScreen> {
  final MapController _mapController = MapController();
  io.Socket? _socket;

  LatLng? _position;
  DateTime? _updatedAt;
  bool _connected = false;
  bool _closing = false;
  bool _disposed = false;
  String? _error;

  bool get _hi => widget.isHindi;

  @override
  void initState() {
    super.initState();
    final lat = widget.user.latitude;
    final lng = widget.user.longitude;
    if (lat != null && lng != null) _position = LatLng(lat, lng);
    _updatedAt = widget.user.updatedAt;
    _connect();
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
      'transports': ['websocket'],
      'autoConnect': false,
      // Without this the library reuses the previous screen's cached
      // connection, along with its stale listeners.
      'forceNew': true,
      'auth': {'token': token},
    });
    _socket = socket;
    debugPrint('[Socket] connecting to $kSocketBaseUrl for friend $friendId');

    socket.on('friend_location_update', (dynamic data) {
      debugPrint('[Socket] friend_location_update: $data');
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
          debugPrint('[Socket] subscribe ack: $response');
          if (_disposed || !mounted || response is! Map) return;
          if (response['success'] != true) {
            setState(() => _error = response['message']?.toString());
            return;
          }
          // Initial location is GeoJSON: [longitude, latitude].
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
      debugPrint('[Socket] location_sharing_updated: $data');
      if (data is! Map || data['locationOwnerId']?.toString() != friendId) {
        return;
      }
      if (data['sharingEnabled'] == false) {
        _onSharingStopped(data['message']?.toString());
      } else if (data['sharingEnabled'] == true) {
        subscribe(); // sharing is back on: reload the location
      }
    });

    socket.onConnect((_) {
      debugPrint('[Socket] CONNECTED id=${socket.id}');
      if (_disposed || !mounted) return;
      setState(() {
        _connected = true;
        _error = null;
      });
      subscribe();
    });

    socket.onDisconnect((reason) {
      debugPrint('[Socket] DISCONNECTED: $reason');
      if (!_disposed && mounted) setState(() => _connected = false);
    });
    socket.onConnectError((e) {
      debugPrint('[Socket] CONNECT ERROR: $e');
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
    setState(() => _position = null); // clear the marker
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
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _disposed = true;
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
    final pos = _position;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002E29),
        foregroundColor: Colors.white,
        title: Text(name),
      ),
      body: pos == null
          ? Center(
              child: Text(
                _error ??
                    (_hi
                        ? 'इस मित्र का स्थान अभी उपलब्ध नहीं है'
                        : 'This friend has not shared a location yet'),
                textAlign: TextAlign.center,
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: pos, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.trackloved.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pos,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  bottom: 24.h,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AddressText(
                            latitude: pos.latitude,
                            longitude: pos.longitude,
                            isHindi: _hi,
                            maxLines: 3,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12.sp,
                                color: _connected ? Colors.green : Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '${_connected ? (_hi ? 'लाइव' : 'Live') : (_hi ? 'ऑफलाइन' : 'Offline')}'
                                  ' • ${_hi ? 'अंतिम अपडेट' : 'Last updated'}: ${_timeText(_updatedAt)}'
                                  '${_error != null ? '\n$_error' : ''}',
                                  style: TextStyle(fontSize: 12.5.sp),
                                ),
                              ),
                            ],
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
