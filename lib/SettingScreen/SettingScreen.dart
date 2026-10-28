import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/SettingScreen/ActiveConsentsScreen.dart';
import 'package:track_loved/SettingScreen/ChildToAdultUpgradeScreen.dart';
import 'package:track_loved/SettingScreen/CompanyOwnershipTransferScreen.dart';
import 'package:track_loved/SettingScreen/DeleteAccountScreen.dart';
import 'package:track_loved/SettingScreen/FontSizeSettingScreen.dart';
import 'package:track_loved/SettingScreen/GrievanceDpoScreen.dart';
import 'package:track_loved/SettingScreen/NotificationSettingScreen.dart';
import 'package:track_loved/SettingScreen/PrivacyPolicyViewerScreen.dart';
import 'package:track_loved/SettingScreen/SystemPermissionsScreen.dart';
import 'package:track_loved/SettingScreen/font_scale_provider.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/RequestDataSummaryBodyModel.dart';

class SettingScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const SettingScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  late bool _isHindi;

  // User Profile
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
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
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      final currentScale = ref.read(fontScaleProvider);
      if (box != null) {
        final accountType =
            box.get('account_type', defaultValue: 'minor') as String;
        final adultSubmitted =
            box.get('adult_upgrade_submitted', defaultValue: false) as bool;

        setState(() {
          _userName = (box.get('name', defaultValue: '') ?? '')
              .toString()
              .trim();
          _userPhone = (box.get('phone', defaultValue: '') ?? '')
              .toString()
              .trim();
          _userEmail = (box.get('email', defaultValue: '') ?? '')
              .toString()
              .trim();

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
      }
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
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      if (box != null) {
        setState(() {
          _isCompanyAccountAssigned =
              box.get('company_account_assigned', defaultValue: false) as bool;
          _assignedPersonName =
              box.get('company_assigned_admin_name', defaultValue: '')
                  as String;
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
      }
    } catch (_) {}
  }

  void _revokeAssignment() async {
    final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
    if (box != null) {
      await box.put('company_account_assigned', false);
    }
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

  void _requestDataSummary() {
    String email = _userEmail.trim();
    if (email.isEmpty) {
      try {
        final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
        email = (box?.get('email', defaultValue: '') ?? '').toString().trim();
      } catch (_) {}
    }
    final emailController = TextEditingController(text: email);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F3D38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.download_for_offline_rounded,
                  color: const Color(0xFFD4AF37),
                  size: 24.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? 'डेटा सारांश का अनुरोध (Section 11)'
                        : 'Request Data Summary',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHindi
                        ? 'DPDP अधिनियम, 2023 की धारा 11 (पहुंच का अधिकार) के तहत, पुष्टि करने पर हमारे सर्वर पर संग्रहीत सभी व्यक्तिगत डेटा और साझाकरण विवरण की एक सत्यापित प्रति स्वचालित रूप से आपकी ईमेल पर भेज दी जाएगी।'
                        : 'Under Section 11 (Right to Access) of the DPDP Act, 2023, clicking confirm will automatically compile and email you a verified summary of all your personal data stored on our servers and who it has been shared with.',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    _isHindi
                        ? 'गंतव्य ईमेल (Destination Email):'
                        : 'Destination Email:',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD4AF37),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13.5.sp,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF00E676),
                        size: 18,
                      ),
                      hintText: 'Enter destination email',
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 13.sp,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text(
                  _isHindi ? 'रद्द करें' : 'Cancel',
                  style: GoogleFonts.outfit(color: Colors.white60),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final targetEmail = emailController.text.trim();
                        if (targetEmail.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text(
                                _isHindi
                                    ? 'कृपया मान्य ईमेल दर्ज करें'
                                    : 'Please enter a valid email',
                                style: GoogleFonts.outfit(color: Colors.white),
                              ),
                            ),
                          );
                          return;
                        }

                        setModalState(() {
                          isLoading = true;
                        });

                        try {
                          final service = ref.read(authServiceProvider);
                          final res = await service.requestDataSummaryData(
                            RequestDataSummaryBodyModel(email: targetEmail),
                          );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.message ??
                                      (_isHindi
                                          ? 'आपका सत्यापित डेटा सारांश संग्रह आपको ईमेल कर दिया गया है।'
                                          : 'Your verified data summary archive has been emailed to you.'),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF0F3D38),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  side: const BorderSide(
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() {
                            isLoading = false;
                          });
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isHindi ? 'पुष्टि करें' : 'Confirm Request',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F3D38),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
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
          _isHindi
              ? 'सेटिंग्स एवं गोपनीयता केंद्र'
              : 'Settings & Privacy Center',
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
                // SECTION 1: Profile & Identity
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'प्रोफ़ाइल एवं पहचान'
                      : 'Profile & Identity',
                  icon: Icons.person_pin_rounded,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        brightGold.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: brandGold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: brightGold.withValues(alpha: 0.2),
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.outfit(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: brightGold,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty
                                  ? _userName
                                  : (_isHindi ? 'खाता धारक' : 'Account Holder'),
                              style: GoogleFonts.outfit(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _userPhone.isNotEmpty
                                  ? _userPhone
                                  : (_userEmail.isNotEmpty
                                        ? _userEmail
                                        : '+91 98765 43210'),
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isAdultVerified
                                        ? const Color(
                                            0xFF00E676,
                                          ).withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: _isAdultVerified
                                          ? const Color(0xFF00E676)
                                          : Colors.orangeAccent,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _isAdultVerified
                                        ? (_isHindi
                                              ? '18+ बालिग खाता'
                                              : 'Adult 18+')
                                        : (_isHindi
                                              ? 'चाइल्ड प्रोटेक्टेड'
                                              : 'Child Protected'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: _isAdultVerified
                                          ? const Color(0xFF00E676)
                                          : Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _isHindi
                            ? 'प्रोफ़ाइल देखें / संपादित करें'
                            : 'Edit Profile',
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: brightGold,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ).then((_) => _loadSettings());
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),

                // SECTION 2: Accessibility & Personalisation
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'सुलभता एवं वैयक्तिकरण'
                      : 'Accessibility & Personalisation',
                  icon: Icons.accessibility_new_rounded,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),
                _buildSettingTile(
                  icon: Icons.format_size_rounded,
                  title: _isHindi
                      ? 'टेक्स्ट का आकार बढ़ाएं (Text Size)'
                      : 'Increase Text Size',
                  subtitle: _isHindi
                      ? 'गोपनीयता सूचनाओं और फ़ीड में पठनीयता बढ़ाने के लिए फ़ॉन्ट स्केल समायोजित करें'
                      : 'Scale text dimensions across all privacy notices and in-app feeds to support readability',
                  tag: '$_fontPreset (${(_fontScale * 100).round()}%)',
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
                SizedBox(height: 10.h),
                _buildSettingTile(
                  icon: Icons.notifications_active_rounded,
                  title: _isHindi
                      ? 'सूचनाएं एवं ध्वनि (Notifications & Sound)'
                      : 'Notifications & Sound',
                  subtitle: _isHindi
                      ? 'ट्रैकिंग लूप्स, बैटरी चेतावनी, एसओएस पैनिक अलर्ट और रिंगटोन टॉगल'
                      : 'Toggle alerts for real-time tracking loops, battery warnings, emergency SOS triggers, and tone',
                  tag: _notificationSoundEnabled ? 'Alerts On' : 'Muted',
                  tagColor: _notificationSoundEnabled
                      ? const Color(0xFF00E676)
                      : Colors.white38,
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
                SizedBox(height: 22.h),

                // SECTION 3: Statutory Privacy Control (DPDPA Gateway)
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'वैधानिक गोपनीयता नियंत्रण (DPDPA Gateway)'
                      : 'Statutory Privacy Control (DPDPA Gateway)',
                  icon: Icons.security_rounded,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),

                // My Active Consents
                _buildSettingTile(
                  icon: Icons.rule_rounded,
                  title: _isHindi
                      ? 'मेरी सक्रिय सहमतियां (My Active Consents)'
                      : 'My Active Consents',
                  subtitle: _isHindi
                      ? 'ऑनबोर्डिंग के दौरान दी गई सहमतियों को व्यक्तिगत रूप से देखें और वापस लें (धारा 6(4))'
                      : 'View, manage, or revoke specific data processing activities individually (Section 6(4))',
                  tag: 'DPDPA 6(4)',
                  tagColor: const Color(0xFF00E676),
                  accentColor: const Color(0xFF00E676),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveConsentsScreen(isHindi: _isHindi),
                      ),
                    );
                  },
                ),
                SizedBox(height: 10.h),

                // System Device Permissions
                _buildSettingTile(
                  icon: Icons.perm_device_information_rounded,
                  title: _isHindi
                      ? 'सिस्टम डिवाइस अनुमतियां (Device Permissions)'
                      : 'System Device Permissions',
                  subtitle: _isHindi
                      ? 'सक्रिय हार्डवेयर पैरामीटर जांचें (जीपीएस लोकेशन, संपर्क पता पुस्तिका)'
                      : 'Check active system-level OS parameters (GPS Location, Device Address Book)',
                  accentColor: brightGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SystemPermissionsScreen(isHindi: _isHindi),
                      ),
                    );
                  },
                ),
                SizedBox(height: 10.h),

                // Grievance & DPO Portal (Section 13)
                _buildSettingTile(
                  icon: Icons.gavel_rounded,
                  title: _isHindi
                      ? 'शिकायत एवं DPO पोर्टल (Grievance & DPO)'
                      : 'Grievance & DPO Portal',
                  subtitle: _isHindi
                      ? 'DPDP अधिनियम, 2023 वैधानिक केंद्र • नामित शिकायत अधिकारी एवं DPO एस्केलेशन'
                      : 'DPDP Act, 2023 Statutory Center • Designated Grievance Officer & DPO Escalations',
                  tag: 'Section 13',
                  tagColor: brightGold,
                  accentColor: brightGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GrievanceDpoScreen(isHindi: _isHindi),
                      ),
                    );
                  },
                ),
                SizedBox(height: 10.h),

                // Download My Data Summary Button Tile
                _buildSettingTile(
                  icon: Icons.cloud_download_rounded,
                  title: _isHindi
                      ? '📥 मेरा डेटा सारांश अनुरोध करें'
                      : '📥 Request My Data Summary',
                  subtitle: _isHindi
                      ? 'धारा 11 (पहुंच का अधिकार) • सभी व्यक्तिगत जानकारी और साझाकरण सूची प्राप्त करें'
                      : 'Section 11 Right to Access • Receive a verified archive of stored data & access logs via email',
                  tag: 'Sec 11',
                  tagColor: const Color(0xFF4FC3F7),
                  accentColor: const Color(0xFF4FC3F7),
                  onTap: _requestDataSummary,
                ),
                SizedBox(height: 10.h),

                // Direct Privacy Policy Link
                _buildSettingTile(
                  icon: Icons.policy_rounded,
                  title: _isHindi
                      ? 'गोपनीयता नीति (Direct Privacy Notice)'
                      : 'Privacy Policy (Direct In-App)',
                  subtitle: _isHindi
                      ? 'बिना किसी बाहरी लॉगिन के सीधे इन-ऐप आधिकारिक DPDP कानूनी नोटिस पढ़ें'
                      : 'Read official statutory DPDP notice natively without requiring separate external login',
                  accentColor: Colors.white70,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrivacyPolicyViewerScreen(isHindi: _isHindi),
                      ),
                    );
                  },
                ),
                SizedBox(height: 22.h),

                // SECTION: Corporate & Account Lifecycle
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'पहचान एवं कॉर्पोरेट प्रशासन'
                      : 'Lifecycle & Corporate Admin',
                  icon: Icons.business_center_outlined,
                  brightGold: brightGold,
                ),
                SizedBox(height: 10.h),

                // Upgrade Minor to Adult
                _buildSettingTile(
                  icon: Icons.how_to_reg_rounded,
                  title: _isHindi
                      ? 'चाइल्ड से बालिग खाता अपग्रेड (18+)'
                      : 'Upgrade: Child to Adult Account (18+)',
                  subtitle: _isAdultVerified
                      ? (_isHindi
                            ? 'सत्यापन सक्रिय है'
                            : 'Adult verified account active')
                      : (_isHindi
                            ? '18 वर्ष पूर्ण होने पर स्वतंत्र वयस्क खाते में बदलें (Age-out transition)'
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
                SizedBox(height: 10.h),

                // Company Ownership Transfer
                _buildSettingTile(
                  icon: Icons.swap_horiz_rounded,
                  title: _isHindi
                      ? 'कंपनी स्वामित्व हस्तांतरण (Permanent Handover)'
                      : 'Company Ownership Transfer & Admin Change',
                  subtitle: _isHindi
                      ? 'कंपनी छोड़ने पर नए व्यवस्थापक को स्वामित्व और आधिकारिक नंबर सौंपें'
                      : 'Permanently delegate company ownership & transfer billing controls to successor',
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
                if (_isCompanyAccountAssigned) ...[
                  SizedBox(height: 10.h),
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
                SizedBox(height: 22.h),

                // SECTION 4: Account Termination & Data Cleansing
                _buildCategoryHeader(
                  title: _isHindi
                      ? 'खाता समाप्ति एवं डेटा सफाई'
                      : 'Account Termination & Data Cleansing',
                  icon: Icons.delete_sweep_rounded,
                  brightGold: Colors.redAccent,
                ),
                SizedBox(height: 10.h),
                _buildSettingTile(
                  icon: Icons.delete_forever_rounded,
                  title: _isHindi
                      ? 'सभी डेटा एवं खाता हटाएं'
                      : 'Delete All Data & Account',
                  subtitle: _isHindi
                      ? 'वैश्विक क्लाउड सिस्टम से अपनी प्रोफ़ाइल और ऐतिहासिक जीपीएस लॉग को स्थायी रूप से मिटाएं'
                      : 'Permanently purge your profile from global cloud systems & wipe historical telemetry',
                  tag: 'Irreversible',
                  tagColor: Colors.redAccent,
                  accentColor: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeleteAccountScreen(isHindi: _isHindi),
                      ),
                    );
                  },
                ),
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
            fontSize: 14.sp,
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
                            fontSize: 14.sp,
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
                      fontSize: 11.8.sp,
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
              size: 15.sp,
            ),
          ],
        ),
      ),
    );
  }
}
