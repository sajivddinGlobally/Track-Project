import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/SettingScreen/ChildToAdultUpgradeScreen.dart';
import 'package:track_loved/SettingScreen/CompanyOwnershipTransferScreen.dart';
import 'package:track_loved/SettingScreen/FontSizeSettingScreen.dart';
import 'package:track_loved/SettingScreen/NotificationSettingScreen.dart';
import 'package:track_loved/SettingScreen/font_scale_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const SettingScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  late bool _isHindi;

  // User Profile
  bool _isAdultVerified = false;

  // Font Size Settings
  double _fontScale = 1.0;
  String _fontPreset = 'Default';

  // Notification Sound Settings
  bool _notificationSoundEnabled = true;
  String _selectedTone = 'Default Chime';

  // Assigned Person state
  bool _isCompanyAccountAssigned = false;
  String _assignedPersonName = '';
  String _assignedPersonContact = '';
  String _assignedPersonRole = 'Corporate Super Admin';

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadSettings();
    _loadCompanyData();
  }

  void _loadSettings() {
    try {
      final box = Hive.box('userdata');
      final currentScale = ref.read(fontScaleProvider);
      setState(() {
        final accountType =
            box.get('account_type', defaultValue: 'minor') as String;
        final adultSubmitted =
            box.get('adult_upgrade_submitted', defaultValue: false) as bool;
        _isAdultVerified = accountType == 'adult' || adultSubmitted;

        _fontScale = currentScale;
        _fontPreset =
            box.get(
                  'font_preset_label',
                  defaultValue: box.get(
                    'app_font_preset',
                    defaultValue: _getPresetFromScale(_fontScale),
                  ),
                )
                as String;

        _notificationSoundEnabled =
            box.get(
                  'notif_sound_enabled',
                  defaultValue: box.get(
                    'notification_sound_enabled',
                    defaultValue: true,
                  ),
                )
                as bool;
        _selectedTone =
            box.get(
                  'notif_selected_tone',
                  defaultValue: box.get(
                    'notification_sound_tone',
                    defaultValue: 'Default Chime',
                  ),
                )
                as String;
      });
    } catch (_) {}
  }

  String _getPresetFromScale(double scale) {
    if (scale <= 0.88) return 'Small';
    if (scale <= 1.05) return 'Default';
    if (scale <= 1.2) return 'Large';
    return 'Extra Large';
  }

  void _loadCompanyData() {
    try {
      final box = Hive.box('userdata');
      setState(() {
        _isCompanyAccountAssigned =
            box.get('company_account_assigned', defaultValue: false) as bool;
        _assignedPersonName =
            box.get('company_assigned_admin_name', defaultValue: '') as String;
        _assignedPersonContact =
            box.get('company_assigned_admin_contact', defaultValue: '')
                as String;
        _assignedPersonRole =
            box.get(
                  'company_assigned_admin_role',
                  defaultValue: 'Corporate Super Admin',
                )
                as String;
      });
    } catch (_) {}
  }

  void _revokeAssignment() async {
    final box = Hive.box('userdata');
    await box.put('company_account_assigned', false);
    _loadCompanyData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isHindi
              ? 'असाइनमेंट सफलतापूर्वक निरस्त कर दिया गया है'
              : 'Assignment successfully revoked',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F3D38),
        duration: const Duration(seconds: 2),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isHindi ? 'सेटिंग्स एवं प्राथमिकताएं' : 'Settings & Preferences',
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
                // User Profile Header Overview Card
                // Container(
                //   padding: EdgeInsets.all(16.r),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: [
                //         brightGold.withValues(alpha: 0.15),
                //         Colors.white.withValues(alpha: 0.04),
                //       ],
                //     ),
                //     borderRadius: BorderRadius.circular(16.r),
                //     border: Border.all(color: brandGold.withValues(alpha: 0.4)),
                //   ),
                //   child: Row(
                //     children: [
                //       CircleAvatar(
                //         radius: 24.r,
                //         backgroundColor: brightGold.withValues(alpha: 0.2),
                //         child: Text(
                //           _userName.isNotEmpty
                //               ? _userName[0].toUpperCase()
                //               : 'U',
                //           style: GoogleFonts.outfit(
                //             fontSize: 20.sp,
                //             fontWeight: FontWeight.bold,
                //             color: brightGold,
                //           ),
                //         ),
                //       ),
                //       SizedBox(width: 14.w),
                //       Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Text(
                //               _userName.isNotEmpty
                //                   ? _userName
                //                   : (_isHindi
                //                         ? 'उपयोगकर्ता'
                //                         : 'Account Holder'),
                //               style: GoogleFonts.outfit(
                //                 fontSize: 16.sp,
                //                 fontWeight: FontWeight.bold,
                //                 color: Colors.white,
                //               ),
                //             ),
                //             SizedBox(height: 2.h),
                //             Text(
                //               _userPhone.isNotEmpty ? _userPhone : _userEmail,
                //               style: GoogleFonts.outfit(
                //                 fontSize: 12.5.sp,
                //                 color: Colors.white70,
                //               ),
                //             ),
                //             SizedBox(height: 6.h),
                //             Row(
                //               children: [
                //                 Container(
                //                   padding: EdgeInsets.symmetric(
                //                     horizontal: 8.w,
                //                     vertical: 3.h,
                //                   ),
                //                   decoration: BoxDecoration(
                //                     color: _isAdultVerified
                //                         ? const Color(
                //                             0xFF00E676,
                //                           ).withValues(alpha: 0.15)
                //                         : Colors.orange.withValues(alpha: 0.2),
                //                     borderRadius: BorderRadius.circular(6.r),
                //                     border: Border.all(
                //                       color: _isAdultVerified
                //                           ? const Color(0xFF00E676)
                //                           : Colors.orangeAccent,
                //                       width: 0.8,
                //                     ),
                //                   ),
                //                   child: Text(
                //                     _isAdultVerified
                //                         ? (_isHindi
                //                               ? '18+ बालिग खाता'
                //                               : '18+ Adult Verified')
                //                         : (_isHindi
                //                               ? 'नाबालिग / चाइल्ड खाता'
                //                               : 'Minor / Child Account'),
                //                     style: GoogleFonts.outfit(
                //                       fontSize: 10.5.sp,
                //                       fontWeight: FontWeight.bold,
                //                       color: _isAdultVerified
                //                           ? const Color(0xFF00E676)
                //                           : Colors.orangeAccent,
                //                     ),
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // SizedBox(height: 24.h),

                // Category 1: Display & Appearance
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'प्रदर्शन एवं टेक्स्ट'
                      : 'Display & Appearance',
                  icon: Icons.palette_outlined,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),
                _buildSettingTile(
                  icon: Icons.format_size_rounded,
                  title: _isHindi ? 'फ़ॉन्ट का आकार' : 'Font Size & Scaling',
                  subtitle: _isHindi
                      ? 'वर्तमान: $_fontPreset (${(_fontScale * 100).round()}%) • आकार बदलने के लिए टैप करें'
                      : 'Current: $_fontPreset (${(_fontScale * 100).round()}%) • Tap to adjust',
                  accentColor: brightGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FontSizeSettingScreen(isHindi: _isHindi),
                      ),
                    ).then((_) => _loadSettings());
                  },
                ),
                SizedBox(height: 20.h),

                // Category 2: Sounds & Alerts
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'ध्वनि एवं सूचनाएं'
                      : 'Audio & Notifications',
                  icon: Icons.volume_up_outlined,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),
                _buildSettingTile(
                  icon: Icons.notifications_active_rounded,
                  title: _isHindi
                      ? 'सूचनाएं एवं रिंगटोन'
                      : 'Notifications & Tone Settings',
                  subtitle: _isHindi
                      ? 'टोन: $_selectedTone • ${_notificationSoundEnabled ? 'ध्वनि सक्रिय' : 'मौन'}'
                      : 'Tone: $_selectedTone • ${_notificationSoundEnabled ? 'Alerts Sound On' : 'Muted'}',
                  accentColor: brightGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationSettingScreen(isHindi: _isHindi),
                      ),
                    ).then((_) => _loadSettings());
                  },
                ),
                SizedBox(height: 20.h),

                // Category 3: Account Lifecycle & Legal Age
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'पहचान एवं खाता स्थिति'
                      : 'Identity & Legal Lifecycle',
                  icon: Icons.shield_outlined,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),
                _buildSettingTile(
                  icon: Icons.how_to_reg_rounded,
                  title: _isHindi
                      ? 'चाइल्ड से बालिग खाता अपग्रेड (18+)'
                      : 'Upgrade: Child to Adult Account (18+)',
                  subtitle: _isAdultVerified
                      ? (_isHindi
                            ? 'सत्यापन अनुरोध सबमिट हो चुका है'
                            : 'Adult verification request active')
                      : (_isHindi
                            ? '18 वर्ष पूर्ण होने पर स्वतंत्र वयस्क खाते में बदलें (KYC प्रमाणीकरण)'
                            : 'Transition minor account to adult self-governed account with ID proof'),
                  tag: _isAdultVerified
                      ? (_isHindi ? 'सत्यापित' : 'Active 18+')
                      : (_isHindi ? 'अपग्रेड करें' : 'Upgrade'),
                  tagColor: _isAdultVerified
                      ? const Color(0xFF00E676)
                      : Colors.orangeAccent,
                  accentColor: brightGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChildToAdultUpgradeScreen(isHindi: _isHindi),
                      ),
                    ).then((_) => _loadSettings());
                  },
                ),
                SizedBox(height: 20.h),

                // Category 4: Corporate & Company Management
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'कॉर्पोरेट एवं कंपनी प्रशासन'
                      : 'Company Administration',
                  icon: Icons.business_center_outlined,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),

                // Company Ownership Transfer Tile
                _buildSettingTile(
                  icon: Icons.swap_horiz_rounded,
                  title: _isHindi
                      ? 'कंपनी स्वामित्व हस्तांतरण (Permanent Handover)'
                      : 'Company Ownership Transfer & Admin Change',
                  subtitle: _isHindi
                      ? 'कंपनी छोड़ने पर नए व्यवस्थापक को स्वामित्व और आधिकारिक नंबर सौंपें'
                      : 'Permanently delegate company ownership & update official contact phone to successor',
                  tag: _isHindi ? 'हस्तांतरण' : 'Handover',
                  tagColor: Colors.orangeAccent,
                  accentColor: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CompanyOwnershipTransferScreen(isHindi: _isHindi),
                      ),
                    ).then((_) => _loadCompanyData());
                  },
                ),

                // If Company Assigned Banner
                if (_isCompanyAccountAssigned) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: brandGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFF00E676),
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_isHindi ? 'सौंपा गया एडमिन:' : 'Assigned Administrator:'} $_assignedPersonName',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$_assignedPersonContact • $_assignedPersonRole',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: _isHindi ? 'असाइनमेंट रद्द करें' : 'Revoke',
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: _revokeAssignment,
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 36.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required IconData icon,
    required Color brightGold,
  }) {
    return Row(
      children: [
        Icon(icon, color: brightGold, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14.5.sp,
            fontWeight: FontWeight.bold,
            color: brightGold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    String? tag,
    Color? tagColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: (tagColor ?? accentColor).withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: (tagColor ?? accentColor).withValues(
                                alpha: 0.4,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: tagColor ?? accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      color: Colors.white60,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
