import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/SettingScreen/font_scale_provider.dart';

class FontSizeSettingScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const FontSizeSettingScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<FontSizeSettingScreen> createState() =>
      _FontSizeSettingScreenState();
}

class _FontSizeSettingScreenState extends ConsumerState<FontSizeSettingScreen> {
  late bool _isHindi;
  double _fontScale = 1.0;
  String _fontPreset = 'Default';

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadFontScale();
  }

  void _loadFontScale() {
    try {
      final box = Hive.box('userdata');
      _fontScale = (box.get('app_font_scale', defaultValue: 1.0) as num)
          .toDouble();
      _fontPreset = box.get('font_preset_label', defaultValue: 'Default')
          as String;
    } catch (_) {}
  }

  void _applyFontScale(double scale, {String? preset}) {
    setState(() {
      _fontScale = double.parse(scale.toStringAsFixed(2));
      if (preset != null) {
        _fontPreset = preset;
      } else {
        if (_fontScale <= 0.88) {
          _fontPreset = 'Small';
        } else if (_fontScale <= 1.05) {
          _fontPreset = 'Default';
        } else if (_fontScale <= 1.20) {
          _fontPreset = 'Large';
        } else {
          _fontPreset = 'Extra Large';
        }
      }
    });

    ref.read(fontScaleProvider.notifier).setScale(_fontScale);

    try {
      final box = Hive.box('userdata');
      box.put('app_font_scale', _fontScale);
      box.put('font_preset_label', _fontPreset);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D38),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F3D38),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _isHindi ? 'फ़ॉन्ट का आकार' : 'Font Size & Display',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isHindi ? 'रीसेट करें' : 'Reset to Default',
            icon: Icon(
              Icons.restart_alt_rounded,
              color: brightGold,
              size: 22.sp,
            ),
            onPressed: () => _applyFontScale(1.0, preset: 'Default'),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3D38), Color(0xFF072420), Color(0xFF031210)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner Card
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: brandGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        color: brightGold,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? 'फ़ॉन्ट का आकार बदलने से ऐप के सभी टेक्स्ट और कार्ड्स का आकार उसी अनुपात में बदल जाएगा।'
                              : 'Adjusting font size scales text across all screens, messages, and cards in the app.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Preset Chips Row
                Text(
                  _isHindi ? 'त्वरित प्रीसेट' : 'Quick Presets',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    _buildPresetChip(
                      'Small',
                      _isHindi ? 'छोटा' : 'Small',
                      0.85,
                      brandGold,
                      brightGold,
                    ),
                    SizedBox(width: 8.w),
                    _buildPresetChip(
                      'Default',
                      _isHindi ? 'सामान्य' : 'Default',
                      1.0,
                      brandGold,
                      brightGold,
                    ),
                    SizedBox(width: 8.w),
                    _buildPresetChip(
                      'Large',
                      _isHindi ? 'बड़ा' : 'Large',
                      1.15,
                      brandGold,
                      brightGold,
                    ),
                    SizedBox(width: 8.w),
                    _buildPresetChip(
                      'Extra Large',
                      _isHindi ? 'अति बड़ा' : 'XL',
                      1.30,
                      brandGold,
                      brightGold,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Slider Control Box
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isHindi ? 'आकार समायोजित करें' : 'Fine Adjustment',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: brightGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: brandGold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '$_fontPreset (${(_fontScale * 100).round()}%)',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: brightGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Text(
                            'A',
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp,
                              color: Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: brightGold,
                                inactiveTrackColor: Colors.white12,
                                thumbColor: brightGold,
                                overlayColor: brightGold.withValues(alpha: 0.2),
                                trackHeight: 4.h,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8.r,
                                ),
                              ),
                              child: Slider(
                                value: _fontScale.clamp(0.80, 1.35),
                                min: 0.80,
                                max: 1.35,
                                divisions: 11,
                                onChanged: (val) => _applyFontScale(val),
                              ),
                            ),
                          ),
                          Text(
                            'A',
                            style: GoogleFonts.outfit(
                              fontSize: 22.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Live Preview Section
                Text(
                  _isHindi ? 'लाइव पूर्वावलोकन' : 'Live Interactive Preview',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                  ),
                ),
                SizedBox(height: 10.h),

                // Preview Card 1: Notification Sample
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          color: const Color(0xFF00E676),
                          size: 20.sp * _fontScale,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isHindi ? 'सुरक्षा सूचना' : 'Safety Alert Notification',
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp * _fontScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              _isHindi
                                  ? 'आपके परिवार का सदस्य सुरक्षित स्थान पर पहुंच गया है।'
                                  : 'Your family member arrived safely at the designated location.',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp * _fontScale,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Preview Card 2: Profile / Address Preview
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'कंपनी और प्रोफ़ाइल विवरण' : 'Corporate Identity Preview',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp * _fontScale,
                          fontWeight: FontWeight.bold,
                          color: brightGold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'SwiftLogistics India Pvt Ltd • GST: 07ABCDE1234F1Z5',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp * _fontScale,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '212, BB Tower, Sector 62, Noida, Uttar Pradesh - 201301',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp * _fontScale,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Save / Done Button
                Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: brandGold.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      _isHindi ? 'फ़ॉन्ट आकार सहेजें' : 'Save & Apply Font Size',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF072420),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String presetKey,
    String label,
    double scale,
    Color brandGold,
    Color brightGold,
  ) {
    final isSelected = (_fontScale - scale).abs() < 0.05;

    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFontScale(scale, preset: presetKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? brightGold.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? brightGold : Colors.white24,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Aa',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp * scale,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? brightGold : Colors.white70,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? brightGold : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
