import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// Reverse-geocodes coordinates to a readable address, with an in-memory cache
/// (keyed to ~11 m) so lists and live updates do not repeat lookups.
class AddressResolver {
  static final Map<String, String?> _cache = {};

  static String _key(double lat, double lng, bool hindi) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)},$hindi';

  static Future<String?> resolve(
    double lat,
    double lng, {
    bool hindi = false,
  }) async {
    final key = _key(lat, lng, hindi);
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        lat,
        lng,
        locale: Locale(hindi ? 'hi' : 'en', 'IN'),
      );
      if (places.isEmpty) return _cache[key] = null;
      final p = places.first;
      final parts = <String>[];
      for (final part in [
        p.name,
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ]) {
        final v = part?.trim() ?? '';
        if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
      }
      return _cache[key] = parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      debugPrint('[Address] lookup failed: $e');
      return null; // not cached, so a later build can retry
    }
  }
}

/// Shows the address for [latitude]/[longitude]; falls back to coordinates
/// while loading or if the lookup fails.
class AddressText extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final bool isHindi;
  final TextStyle? style;
  final int? maxLines;
  final String unavailableText;

  const AddressText({
    super.key,
    required this.latitude,
    required this.longitude,
    this.isHindi = false,
    this.style,
    this.maxLines,
    this.unavailableText = 'Location not available',
  });

  @override
  State<AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<AddressText> {
  String? _address;

  String get _fallback => widget.latitude == null || widget.longitude == null
      ? widget.unavailableText
      : '${widget.latitude!.toStringAsFixed(4)}, '
            '${widget.longitude!.toStringAsFixed(4)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AddressText old) {
    super.didUpdateWidget(old);
    if (old.latitude != widget.latitude ||
        old.longitude != widget.longitude ||
        old.isHindi != widget.isHindi) {
      _load();
    }
  }

  Future<void> _load() async {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return;
    final address = await AddressResolver.resolve(
      lat,
      lng,
      hindi: widget.isHindi,
    );
    if (mounted && address != null) setState(() => _address = address);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _address ?? _fallback,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
