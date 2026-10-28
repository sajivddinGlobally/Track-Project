import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/DeleteUserAccountBodyModel.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const DeleteAccountScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _confirmTextController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedReason = 'Privacy Concerns';
  bool _isAcknowledged = false;
  bool _isPurging = false;
  bool _isSendingOtp = false;

  bool _isChildProfile = false;
  bool _isBusinessProfile = false;

  final List<String> _reasonsEn = [
    'Privacy Concerns',
    'Not Using App',
    'Moving Platforms',
    'Other',
  ];

  final List<String> _reasonsHi = [
    'गोपनीयता संबंधी चिंताएं (Privacy Concerns)',
    'ऐप का उपयोग नहीं कर रहे (Not Using App)',
    'अन्य प्लेटफॉर्म पर जा रहे (Moving Platforms)',
    'अन्य कारण (Other)',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileRoles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendDeletionOtp(silent: true);
    });
  }

  @override
  void dispose() {
    _confirmTextController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _loadProfileRoles() {
    try {
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      if (box != null) {
        final accountType =
            box.get('account_type', defaultValue: 'adult') as String;
        final adultSubmitted =
            box.get('adult_upgrade_submitted', defaultValue: false) as bool;
        final isMinor = accountType == 'minor' && !adultSubmitted;

        final isCompany =
            box.get('isCompanyProfileComplete', defaultValue: false) as bool;
        final companyAssigned =
            box.get('company_account_assigned', defaultValue: false) as bool;

        setState(() {
          _isChildProfile = isMinor;
          _isBusinessProfile = isCompany || companyAssigned;
        });
      }
    } catch (_) {}
  }

  String _getBackendReasonKey(String selected) {
    if (selected.contains('Privacy Concerns')) return 'Privacy Concerns';
    if (selected.contains('Not Using App')) return 'Not Using App';
    if (selected.contains('Moving Platforms')) return 'Moving Platforms';
    return 'Other';
  }

  Future<void> _sendDeletionOtp({bool silent = false}) async {
    if (_isSendingOtp) return;
    setState(() => _isSendingOtp = true);

    try {
      final res = await ref
          .read(authServiceProvider)
          .sendDeleteAccountOtpData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message ??
                (widget.isHindi
                    ? 'सत्यापन OTP आपके पंजीकृत संपर्क पर भेज दिया गया है।'
                    : 'Verification OTP has been sent to your registered contact.'),
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0F3D38),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _executeHardDataPurge() async {
    if (_isChildProfile) {
      _showChildLockedDialog();
      return;
    }

    if (!_isAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isHindi
                ? 'कृपया आगे बढ़ने के लिए शपथ पत्र चेकबॉक्स चुनें'
                : 'Please acknowledge the irrevocable action checkbox',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_confirmTextController.text.trim() != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isHindi
                ? 'सत्यापन के लिए कृपया बॉक्स में "DELETE" (बड़े अक्षरों में) टाइप करें'
                : 'Please type exact word "DELETE" in capital letters to confirm',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final otpText = _otpController.text.trim();
    if (otpText.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isHindi
                ? 'कृपया 6 अंकों का सत्यापन ओटीपी दर्ज करें'
                : 'Please enter 6-digit verification OTP',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPurging = true);

    try {
      final body = DeleteUserAccountBodyModel(
        confirmationWord: _confirmTextController.text.trim(),
        otp: otpText,
        reason: _getBackendReasonKey(_selectedReason),
      );

      final res = await ref
          .read(authServiceProvider)
          .deleteUserAccountData(body);

      if (res.success == true) {
        // 4. Post-Deletion Action (App Level Clean-up)
        final box = Hive.isBoxOpen('userdata')
            ? Hive.box('userdata')
            : await Hive.openBox('userdata');
        await box.clear();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message ??
                  (widget.isHindi
                      ? 'आपका खाता और डेटा स्थायी रूप से मिटा दिया गया है।'
                      : 'Your account and data have been permanently deleted.'),
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message ??
                  (widget.isHindi
                      ? 'खाता मिटाने में विफल'
                      : 'Failed to delete account'),
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      log(e.toString());
    } finally {
      if (mounted) setState(() => _isPurging = false);
    }
  }

  void _showChildLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 24.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                widget.isHindi
                    ? 'अभिभावक नियंत्रण गेट'
                    : 'Parental Control Gate',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          widget.isHindi
              ? '🛡️ नाबालिग खाते स्वयं को नहीं मिटा सकते। यह कार्रवाई केवल लिंक किए गए मूल अभिभावक (Parent) द्वारा आधार ओटीपी/डिजीलॉकर सत्यापन के माध्यम से पेरेंट डैशबोर्ड से ही शुरू की जा सकती है।'
              : '🛡️ Minor accounts cannot delete themselves. This action can only be initiated by the linked Parent Account via the Parent Dashboard, authenticated by Aadhaar OTP/DigiLocker verification.',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13.sp,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              widget.isHindi ? 'समझ गया' : 'Understood',
              style: GoogleFonts.outfit(
                color: const Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    final reasons = widget.isHindi ? _reasonsHi : _reasonsEn;
    if (!reasons.contains(_selectedReason)) {
      _selectedReason = reasons.first;
    }

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
          widget.isHindi
              ? 'खाता एवं डेटा स्थायी निष्कासन'
              : 'Delete Account & Erasure',
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
                // Warning Header Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isHindi
                                  ? 'चेतावनी: यह कार्रवाई स्थायी और पूरी तरह से अपरिवर्तनीय है!'
                                  : 'WARNING: This action is permanent and completely irreversible.',
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              widget.isHindi
                                  ? 'एक बार संसाधित होने के बाद, सभी खाता कॉन्फ़िगरेशन, प्रोफ़ाइल सेटअप और नेटवर्क स्थायी रूप से नष्ट हो जाएंगे।'
                                  : 'Once processed, all account configurations, profile setups, and networks will be permanently destroyed.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12.sp,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // Card: What will be permanently erased
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
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: brightGold,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.isHindi
                                ? '📦 क्या स्थायी रूप से मिटा दिया जाएगा:'
                                : '📦 WHAT WILL BE PERMANENTLY ERASED:',
                            style: GoogleFonts.outfit(
                              color: brightGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      _buildBulletItem(
                        widget.isHindi
                            ? 'व्यक्तिगत प्रोफ़ाइल (नाम, ईमेल आईडी, संपर्क नंबर और तस्वीरें)'
                            : 'Personal Profile (Name, Email ID, Contact Number, and Photos)',
                      ),
                      _buildBulletItem(
                        widget.isHindi
                            ? 'सभी ऐतिहासिक टेलीमेट्री (एसओएस ट्रिगर, जीपीएस लॉग और सर्वर कैश)'
                            : 'All Historical Telemetry (SOS triggers, logs, and server cache)',
                      ),
                      _buildBulletItem(
                        widget.isHindi
                            ? 'सभी सर्कल लिंक (आपके संपर्क तुरंत आपके लोकेशन तक पहुंच खो देंगे)'
                            : 'All Circle Links (Your connections will instantly lose access to you)',
                      ),
                      _buildBulletItem(
                        widget.isHindi
                            ? 'नौकरी और अवसर इतिहास (कोई भी सक्रिय नौकरी आवेदन या पोस्टिंग)'
                            : 'Job History (Any active job applications or company listings)',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Role Dependent Warnings
                if (_isChildProfile)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.orangeAccent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.orangeAccent,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              widget.isHindi
                                  ? '🛡️ अभिभावक नियंत्रण गेट (चाइल्ड प्रोफाइल)'
                                  : '🛡️ Parental Control Gate: Child Profile Locked',
                              style: GoogleFonts.outfit(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          widget.isHindi
                              ? 'नाबालिग खाते स्वयं को नहीं मिटा सकते। यह कार्रवाई केवल लिंक किए गए अभिभावक द्वारा आधार ओटीपी के माध्यम से शुरू की जा सकती है।'
                              : 'Minor accounts cannot delete themselves. This action can only be initiated by the linked Parent Account via the Parent Dashboard.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isBusinessProfile)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: brandGold),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business_center,
                              color: brandGold,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              widget.isHindi
                                  ? '⚠️ सक्रिय पोस्टिंग चेतावनी (बिजनेस प्रोफाइल)'
                                  : '⚠️ Active Postings Warning: Business Profile',
                              style: GoogleFonts.outfit(
                                color: brandGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          widget.isHindi
                              ? 'यदि आप यह प्रोफ़ाइल हटाते हैं, तो आपकी सभी वर्तमान नौकरी पोस्टिंग तुरंत हटा दी जाएंगी और सभी आवेदन डेटा को इंटरमीडियरी नियमों के तहत मिटा दिया जाएगा।'
                              : 'If you delete this profile, all current job postings will be immediately unlisted. Static applications in your archive must be deleted from systems.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16.h),

                // Reason for Closure Dropdown
                Text(
                  widget.isHindi
                      ? '💬 खाता बंद करने का कारण (वैकल्पिक)'
                      : '💬 REASON FOR CLOSURE (OPTIONAL)',
                  style: GoogleFonts.outfit(
                    color: brightGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedReason,
                      dropdownColor: const Color(0xFF072420),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13.sp,
                      ),
                      items: reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(r, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Affirmative Action Checkbox
                InkWell(
                  onTap: () =>
                      setState(() => _isAcknowledged = !_isAcknowledged),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _isAcknowledged,
                        activeColor: Colors.redAccent,
                        checkColor: Colors.white,
                        onChanged: (v) =>
                            setState(() => _isAcknowledged = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Text(
                            widget.isHindi
                                ? '* मैं स्पष्ट रूप से समझता/समझती हूँ कि Track Loved Ones App तुरंत सभी ट्रैकिंग सेवाएं समाप्त कर देगा, उत्पादन सर्वर से मेरे व्यक्तिगत रिकॉर्ड को मिटा देगा, और इस डेटा को पुनर्प्राप्त नहीं किया जा सकता है।'
                                : '* I explicitly understand that Track Loved Ones App will immediately terminate all tracking services, purge my personal records from production servers, and that this data cannot be recovered.',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12.sp,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Type DELETE text field
                Text(
                  widget.isHindi
                      ? 'पुष्टि करने के लिए नीचे दिए गए बॉक्स में "DELETE" टाइप करें:'
                      : 'Type exact word "DELETE" in the box below to confirm:',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12.5.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: _confirmTextController,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // OTP verification field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.isHindi
                            ? 'पंजीकृत संपर्क पर भेजा गया सत्यापन OTP दर्ज करें:'
                            : 'Enter verification OTP sent to registered contact:',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _isSendingOtp
                          ? null
                          : () => _sendDeletionOtp(silent: false),
                      borderRadius: BorderRadius.circular(6.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        child: _isSendingOtp
                            ? SizedBox(
                                width: 14.w,
                                height: 14.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: brightGold,
                                ),
                              )
                            : Text(
                                widget.isHindi
                                    ? 'पुनः OTP भेजें'
                                    : 'Resend OTP',
                                style: GoogleFonts.outfit(
                                  color: brightGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15.sp,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '• • • • • •',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white30,
                      letterSpacing: 2,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28.h),

                // Purge Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _isPurging ? null : _executeHardDataPurge,
                    child: _isPurging
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isHindi
                                ? '🛑 मेरा खाता और डेटा स्थायी रूप से मिटाएं'
                                : '🛑 PERMANENTLY PURGE MY ACCOUNT & DATA',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5.sp,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.outfit(
              color: const Color(0xFFD4AF37),
              fontSize: 14.sp,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12.sp,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
