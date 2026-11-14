import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// Reverse-geocodes coordinates to a readable address, prioritizing specific building/premise names,
/// with an in-memory cache keyed to ~1.1m precision so lists and live updates do not repeat lookups unnecessarily.
class AddressResolver {
  static final Map<String, String?> _cache = {};

  // 5 decimal places is ~1.1 meter resolution for fine-grained building precision
  static String _key(double lat, double lng, bool hindi) =>
      '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)},$hindi';

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

      // Check across placemarks for any identified building / premise name
      Placemark bestPlacemark = places.first;
      String? bestBuildingName;

      for (final p in places) {
        final name = p.name?.trim() ?? '';
        final isPlusCode =
            RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]+', caseSensitive: false)
                .hasMatch(name);
        final isOnlyDigits = RegExp(r'^\d+$').hasMatch(name);
        if (name.isNotEmpty && !isPlusCode && !isOnlyDigits) {
          bestBuildingName ??= name;
          bestPlacemark = p;
          break;
        }
      }

      final p = bestPlacemark;
      final parts = <String>[];

      // Helper function to add distinct address elements without redundant duplicates
      void addPart(String? text) {
        final val = text?.trim() ?? '';
        if (val.isEmpty) return;
        final alreadyPresent = parts.any(
          (existing) =>
              existing.toLowerCase() == val.toLowerCase() ||
              (existing.length > 4 &&
                  existing.toLowerCase().contains(val.toLowerCase())) ||
              (val.length > 4 &&
                  val.toLowerCase().contains(existing.toLowerCase())),
        );
        if (!alreadyPresent) {
          parts.add(val);
        }
      }

      // 1. Building / Premise / POI Name first
      if (bestBuildingName != null && bestBuildingName.isNotEmpty) {
        addPart(bestBuildingName);
      } else if (p.name != null && p.name!.isNotEmpty) {
        addPart(p.name);
      }

      // 2. House / Plot / Sub-thoroughfare
      if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) {
        addPart(p.subThoroughfare);
      }

      // 3. Street / Road / Thoroughfare
      if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
        addPart(p.thoroughfare);
      } else if (p.street != null && p.street!.isNotEmpty) {
        addPart(p.street);
      }

      // 4. Sector / Colony / SubLocality
      if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        addPart(p.subLocality);
      }

      // 5. City / Locality
      if (p.locality != null && p.locality!.isNotEmpty) {
        addPart(p.locality);
      }

      // 6. State / Administrative Area
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
        addPart(p.administrativeArea);
      }

      // 7. PIN Code
      if (p.postalCode != null && p.postalCode!.isNotEmpty) {
        addPart(p.postalCode);
      }

      final resolved = parts.isEmpty ? null : parts.join(', ');
      return _cache[key] = resolved;
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
