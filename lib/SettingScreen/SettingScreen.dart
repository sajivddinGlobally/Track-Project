import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/SettingScreen/font_scale_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const SettingScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  late bool _isHindi;

  // Font Size Settings
  double _fontScale = 1.0;
  String _fontPreset = 'Default';

  // Notification Sound Settings
  bool _notificationSoundEnabled = true;
  String _selectedTone = 'Default Chime';
  double _soundVolume = 0.8;
  bool _vibrationEnabled = true;

  final List<Map<String, dynamic>> _soundTones = [
    {
      'id': 'Default Chime',
      'nameEn': 'Default Chime',
      'nameHi': 'डिफ़ॉल्ट चाइम',
      'descEn': 'Classic standard alert chime',
      'descHi': 'मानक क्लासिक अलर्ट चाइम',
      'icon': Icons.notifications_active_rounded,
    },
    {
      'id': 'Gentle Bell',
      'nameEn': 'Gentle Bell',
      'nameHi': 'धीमी घंटी',
      'descEn': 'Soft and pleasant notification tone',
      'descHi': 'शांत और सुखद अधिसूचना टोन',
      'icon': Icons.music_note_rounded,
    },
    {
      'id': 'Alert Pulse',
      'nameEn': 'Alert Pulse',
      'nameHi': 'अलर्ट पल्स',
      'descEn': 'Clear high-priority safety alert tone',
      'descHi': 'स्पष्ट उच्च-प्राथमिकता सुरक्षा अलर्ट',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'id': 'Radar Echo',
      'nameEn': 'Radar Echo',
      'nameHi': 'रडार इको',
      'descEn': 'Distinctive location ping sound',
      'descHi': 'विशिष्ट लोकेशन पिंग ध्वनि',
      'icon': Icons.radar_rounded,
    },
    {
      'id': 'Subtle Beep',
      'nameEn': 'Subtle Beep',
      'nameHi': 'हल्की बीप',
      'descEn': 'Minimal unobtrusive beep',
      'descHi': 'हल्की और शांत बीप ध्वनि',
      'icon': Icons.volume_down_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = Hive.box('userdata');
      final currentScale = ref.read(fontScaleProvider);
      setState(() {
        _fontScale = currentScale;
        _fontPreset = box.get(
          'app_font_preset',
          defaultValue: _getPresetFromScale(_fontScale),
        );
        _notificationSoundEnabled =
            box.get('notification_sound_enabled', defaultValue: true) as bool;
        _selectedTone =
            box.get('notification_sound_tone', defaultValue: 'Default Chime')
                as String;
        _soundVolume =
            (box.get('notification_volume', defaultValue: 0.8) as num)
                .toDouble();
        _vibrationEnabled =
            box.get('notification_vibrate', defaultValue: true) as bool;
      });
    } catch (_) {
      // Fallback to default values
    }
  }

  String _getPresetFromScale(double scale) {
    if (scale <= 0.88) return 'Small';
    if (scale <= 1.05) return 'Default';
    if (scale <= 1.2) return 'Large';
    return 'Extra Large';
  }

  void _saveFontScale(double scale, {String? preset}) {
    final newPreset = preset ?? _getPresetFromScale(scale);
    setState(() {
      _fontScale = scale;
      _fontPreset = newPreset;
    });

    // Update Riverpod provider to scale the entire app immediately
    ref.read(fontScaleProvider.notifier).setScale(scale);

    try {
      final box = Hive.box('userdata');
      box.put('app_font_preset', newPreset);
    } catch (_) {}
  }

  void _saveNotificationSettings({
    bool? soundEnabled,
    String? tone,
    double? volume,
    bool? vibrate,
  }) {
    setState(() {
      if (soundEnabled != null) _notificationSoundEnabled = soundEnabled;
      if (tone != null) _selectedTone = tone;
      if (volume != null) _soundVolume = volume;
      if (vibrate != null) _vibrationEnabled = vibrate;
    });

    try {
      final box = Hive.box('userdata');
      if (soundEnabled != null) {
        box.put('notification_sound_enabled', soundEnabled);
      }
      if (tone != null) box.put('notification_sound_tone', tone);
      if (volume != null) box.put('notification_volume', volume);
      if (vibrate != null) box.put('notification_vibrate', vibrate);
    } catch (_) {}
  }

  void _playTestTone() {
    if (!_notificationSoundEnabled) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.volume_up_rounded,
              color: const Color(0xFFD4AF37),
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _isHindi
                    ? 'ध्वनि पूर्वावलोकन बजाया गया: $_selectedTone'
                    : 'Playing preview: $_selectedTone',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F3D38),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: Color(0xFFC5A038), width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // App Brand Palette (matching Login, Register, Dashboard)
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F3D38),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isHindi ? 'सेटिंग्स' : 'Settings',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 19.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isHindi ? 'डिफ़ॉल्ट रीसेट करें' : 'Reset to Default',
            icon: Icon(
              Icons.restart_alt_rounded,
              color: brightGold,
              size: 22.sp,
            ),
            onPressed: () {
              _saveFontScale(1.0, preset: 'Default');
              _saveNotificationSettings(
                soundEnabled: true,
                tone: 'Default Chime',
                volume: 0.8,
                vibrate: true,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isHindi
                        ? 'सेटिंग्स डिफ़ॉल्ट पर रीसेट कर दी गई हैं'
                        : 'Settings reset to default',
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF0F3D38),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: const BorderSide(color: brandGold, width: 1),
                  ),
                ),
              );
            },
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth > 650
                        ? 560
                        : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 18.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Font Size
                        _buildSectionHeader(
                          icon: Icons.format_size_rounded,
                          title: _isHindi ? 'फ़ॉन्ट का आकार' : 'Font Size',
                          subtitle: _isHindi
                              ? 'ऐप में टेक्स्ट का आकार समायोजित करें'
                              : 'Adjust text size across the application',
                          accentGold: brightGold,
                        ),
                        SizedBox(height: 14.h),
                        _buildFontSizeCard(brandGold, brightGold),
                        SizedBox(height: 26.h),
                        // Section 2: Notification Sound
                        _buildSectionHeader(
                          icon: Icons.notifications_active_rounded,
                          title: _isHindi
                              ? 'सूचना ध्वनि'
                              : 'Notification Sound',
                          subtitle: _isHindi
                              ? 'अलर्ट ध्वनि और सूचना प्राथमिकताएं सेट करें'
                              : 'Set alert sounds & notification preferences',
                          accentGold: brightGold,
                        ),
                        SizedBox(height: 14.h),
                        _buildNotificationSoundCard(brandGold, brightGold),
                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentGold,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(9.r),
          decoration: BoxDecoration(
            color: accentGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: accentGold.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Icon(icon, color: accentGold, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeCard(Color brandGold, Color brightGold) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset Buttons
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
                _isHindi ? 'बहुत बड़ा' : 'XL',
                1.3,
                brandGold,
                brightGold,
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // Interactive Slider
          Row(
            children: [
              Text(
                'A',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: brandGold,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: brightGold,
                    overlayColor: brandGold.withValues(alpha: 0.2),
                    trackHeight: 4.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                  ),
                  child: Slider(
                    value: _fontScale,
                    min: 0.85,
                    max: 1.3,
                    divisions: 3,
                    onChanged: (val) {
                      _saveFontScale(val);
                    },
                  ),
                ),
              ),
              Text(
                'A',
                style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: brightGold,
                ),
              ),
            ],
          ),

          // Size percentage display
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: brandGold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                '${(_fontScale * 100).toInt()}%  ($_fontPreset)',
                style: GoogleFonts.outfit(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: brightGold,
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),
          const Divider(height: 1, color: Colors.white12),
          SizedBox(height: 14.h),

          // Live Preview Box
          Text(
            _isHindi ? 'पूर्वावलोकन (Live Preview)' : 'Live Preview',
            style: GoogleFonts.outfit(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14.r,
                      backgroundColor: const Color(0xFF0F3D38),
                      child: Icon(
                        Icons.shield_rounded,
                        color: brightGold,
                        size: 15.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _isHindi ? 'सुरक्षा अधिसूचना' : 'Safety Notification',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Just now',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5.sp,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _isHindi
                      ? 'आपका प्रियजन सुरक्षित स्थान पर पहुँच गया है। लाइव ट्रैकिंग सक्रिय है।'
                      : 'Your loved one has reached the safe zone. Live location tracking is active.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String key,
    String label,
    double scale,
    Color brandGold,
    Color brightGold,
  ) {
    final isSelected = (_fontScale - scale).abs() < 0.05;

    return Expanded(
      child: GestureDetector(
        onTap: () => _saveFontScale(scale, preset: key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.5.h),
          decoration: BoxDecoration(
            color: isSelected
                ? brandGold
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? brightGold : Colors.white24,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSoundCard(Color brandGold, Color brightGold) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'सूचना ध्वनि सक्षम करें' : 'Enable Sound',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _isHindi
                          ? 'सभी सूचनाओं और संदेशों के लिए ध्वनि बजाएं'
                          : 'Play sound for notifications and messages',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _notificationSoundEnabled,
                activeTrackColor: brandGold,
                onChanged: (val) {
                  _saveNotificationSettings(soundEnabled: val);
                  if (val) _playTestTone();
                },
              ),
            ],
          ),

          if (_notificationSoundEnabled) ...[
            SizedBox(height: 16.h),
            const Divider(height: 1, color: Colors.white12),
            SizedBox(height: 16.h),

            // Sound Tone Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isHindi ? 'ध्वनि टोन चुनें' : 'Select Sound Tone',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _playTestTone,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: brandGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: brandGold.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: brightGold,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _isHindi ? 'टेस्ट करें' : 'Test Sound',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: brightGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // List of Sound Tones
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _soundTones.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final tone = _soundTones[index];
                final isSelected = _selectedTone == tone['id'];

                return GestureDetector(
                  onTap: () {
                    _saveNotificationSettings(tone: tone['id'] as String);
                    _playTestTone();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? brandGold.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected ? brandGold : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tone['icon'] as IconData,
                          size: 20.sp,
                          color: isSelected ? brightGold : Colors.white60,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi ? tone['nameHi'] : tone['nameEn'],
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected ? brightGold : Colors.white,
                                ),
                              ),
                              Text(
                                _isHindi ? tone['descHi'] : tone['descEn'],
                                style: GoogleFonts.outfit(
                                  fontSize: 11.sp,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: brightGold,
                            size: 18.sp,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: Colors.white30,
                            size: 18.sp,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 18.h),
            const Divider(height: 1, color: Colors.white12),
            SizedBox(height: 14.h),

            // Volume Control
            Row(
              children: [
                Icon(
                  _soundVolume == 0
                      ? Icons.volume_mute_rounded
                      : Icons.volume_up_rounded,
                  color: brightGold,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _isHindi ? 'ध्वनि स्तर (Volume)' : 'Volume',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_soundVolume * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: brandGold,
                inactiveTrackColor: Colors.white24,
                thumbColor: brightGold,
                overlayColor: brandGold.withValues(alpha: 0.2),
                trackHeight: 4.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
              ),
              child: Slider(
                value: _soundVolume,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  _saveNotificationSettings(volume: val);
                },
              ),
            ),

            // Vibration Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'सूचना पर कंपन (Vibration)' : 'Vibration',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _isHindi
                            ? 'ध्वनि के साथ फ़ोन को कंपन कराएं'
                            : 'Vibrate device alongside sound notification',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _vibrationEnabled,
                  activeTrackColor: brandGold,
                  onChanged: (val) {
                    _saveNotificationSettings(vibrate: val);
                    if (val) HapticFeedback.mediumImpact();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
