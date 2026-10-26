import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class NotificationSettingScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const NotificationSettingScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState
    extends ConsumerState<NotificationSettingScreen> {
  late bool _isHindi;
  bool _notificationSoundEnabled = true;
  String _selectedTone = 'Default Chime';
  double _soundVolume = 0.8;
  bool _vibrationEnabled = true;
  bool _criticalAlertsEnabled = true;

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
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    try {
      final box = Hive.box('userdata');
      _notificationSoundEnabled =
          box.get('notif_sound_enabled', defaultValue: true) as bool;
      _selectedTone =
          box.get('notif_selected_tone', defaultValue: 'Default Chime')
              as String;
      _soundVolume =
          (box.get('notif_sound_volume', defaultValue: 0.8) as num).toDouble();
      _vibrationEnabled =
          box.get('notif_vibration_enabled', defaultValue: true) as bool;
      _criticalAlertsEnabled =
          box.get('notif_critical_alerts', defaultValue: true) as bool;
    } catch (_) {}
  }

  void _saveNotificationSettings() {
    try {
      final box = Hive.box('userdata');
      box.put('notif_sound_enabled', _notificationSoundEnabled);
      box.put('notif_selected_tone', _selectedTone);
      box.put('notif_sound_volume', _soundVolume);
      box.put('notif_vibration_enabled', _vibrationEnabled);
      box.put('notif_critical_alerts', _criticalAlertsEnabled);
    } catch (_) {}
  }

  void _previewTone(String toneName) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Color(0xFFD4AF37), size: 18),
            SizedBox(width: 8.w),
            Text(
              _isHindi ? 'प्ले हो रहा है: $toneName' : 'Playing: $toneName',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.sp),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F3D38),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
          side: const BorderSide(color: Color(0xFFC5A038), width: 1),
        ),
      ),
    );
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
          onPressed: () {
            _saveNotificationSettings();
            Navigator.pop(context, true);
          },
        ),
        title: Text(
          _isHindi ? 'सूचनाएं एवं ध्वनि' : 'Notifications & Sounds',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                // Master Sound Switch Card
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: brightGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _notificationSoundEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: brightGold,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isHindi ? 'सूचना ध्वनि' : 'Notification Sounds',
                              style: GoogleFonts.outfit(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _isHindi
                                  ? 'सभी अलर्ट और संदेशों के लिए ध्वनि सक्षम करें'
                                  : 'Play sounds for incoming alerts & updates',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _notificationSoundEnabled,
                        activeTrackColor: brightGold,
                        onChanged: (val) {
                          setState(() => _notificationSoundEnabled = val);
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                if (_notificationSoundEnabled) ...[
                  // Volume Slider Card
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isHindi ? 'ध्वनि की तीव्रता' : 'Alert Volume',
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${(_soundVolume * 100).round()}%',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: brightGold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Icon(Icons.volume_mute, color: Colors.white54, size: 20.sp),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: brightGold,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: brightGold,
                                  trackHeight: 4.h,
                                ),
                                child: Slider(
                                  value: _soundVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    setState(() => _soundVolume = val);
                                    _saveNotificationSettings();
                                  },
                                ),
                              ),
                            ),
                            Icon(Icons.volume_up, color: brightGold, size: 20.sp),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Select Tone Section
                  Text(
                    _isHindi ? 'अलर्ट रिंगटोन चुनें' : 'Choose Alert Tone',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: brightGold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _soundTones.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final tone = _soundTones[index];
                      final isSelected = tone['id'] == _selectedTone;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTone = tone['id']);
                          _saveNotificationSettings();
                          _previewTone(tone['nameEn']);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? brightGold.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isSelected
                                  ? brightGold
                                  : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tone['icon'] as IconData,
                                color: isSelected ? brightGold : Colors.white60,
                                size: 22.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isHindi
                                          ? tone['nameHi'] as String
                                          : tone['nameEn'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.sp,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      _isHindi
                                          ? tone['descHi'] as String
                                          : tone['descEn'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5.sp,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: isSelected ? brightGold : Colors.white38,
                                  size: 24.sp,
                                ),
                                onPressed: () => _previewTone(tone['nameEn']),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF00E676),
                                  size: 20.sp,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                ],

                // Vibration Toggle Card
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vibration_rounded, color: brightGold, size: 22.sp),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isHindi ? 'कंपन (Vibration)' : 'Haptic Vibration',
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _isHindi
                                  ? 'सूचना आने पर डिवाइस को वाइब्रेट करें'
                                  : 'Vibrate device on important alerts',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _vibrationEnabled,
                        activeTrackColor: brightGold,
                        onChanged: (val) {
                          if (val) HapticFeedback.mediumImpact();
                          setState(() => _vibrationEnabled = val);
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Critical Alerts Card
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, color: const Color(0xFF00E676), size: 22.sp),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isHindi ? 'आपातकालीन सुरक्षा अलर्ट' : 'Critical Safety Alerts',
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _isHindi
                                  ? 'साइलेंट मोड में भी उच्च प्राथमिकता वाले अलर्ट बजाएं'
                                  : 'Bypass Do Not Disturb for emergency track alerts',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _criticalAlertsEnabled,
                        activeTrackColor: brightGold,
                        onChanged: (val) {
                          setState(() => _criticalAlertsEnabled = val);
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Done Button
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
                    onPressed: () {
                      _saveNotificationSettings();
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      _isHindi ? 'सेटिंग्स सुरक्षित करें' : 'Save Notification Preferences',
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
}
