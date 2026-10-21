import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(_getInitialScale());

  static double _getInitialScale() {
    try {
      if (Hive.isBoxOpen('userdata')) {
        final box = Hive.box('userdata');
        final saved = box.get('app_font_scale', defaultValue: 1.0);
        if (saved is num) {
          return saved.toDouble();
        }
      }
    } catch (_) {}
    return 1.0;
  }

  void setScale(double newScale) {
    state = newScale;
    try {
      if (Hive.isBoxOpen('userdata')) {
        final box = Hive.box('userdata');
        box.put('app_font_scale', newScale);
      }
    } catch (_) {}
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier();
});
