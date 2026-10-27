import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackRatingScreen extends StatefulWidget {
  final bool isHindi;
  const FeedbackRatingScreen({super.key, this.isHindi = false});

  @override
  State<FeedbackRatingScreen> createState() => _FeedbackRatingScreenState();
}

class _FeedbackRatingScreenState extends State<FeedbackRatingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _feedbackController = TextEditingController();

  late bool _isHindi;
  int _rating = 0;
  final Set<String> _selectedIssues = {};
  bool _isSubmitting = false;

  // DPDP Act Compliance State Variables
  File? _attachedScreenshot;
  String? _attachedFileName;
  bool _includeDiagnostics = false; // Strictly FALSE (unchecked) by default

  // Theme constants matching brand guidelines
  static const Color darkBg = Color(0xFF002E29);
  static const Color surfaceDark = Color(0xFF072420);
  static const Color cardBg = Color(0xFF0F3D38);
  static const Color brandGold = Color(0xFFC5A038);
  static const Color brightGold = Color(0xFFD4AF37);
  static const Color starActive = Color(0xFFFFB300);

  final List<Map<String, dynamic>> _issueCategories = [
    {
      'id': 'gps_delay',
      'title_en': 'Location Lag / GPS Accuracy',
      'title_hi': 'लोकेशन लैग / GPS सटीकता',
      'icon': Icons.my_location_rounded,
    },
    {
      'id': 'battery',
      'title_en': 'Battery Consumption',
      'title_hi': 'बैटरी का अधिक उपयोग',
      'icon': Icons.battery_alert_rounded,
    },
    {
      'id': 'map_speed',
      'title_en': 'Map Loading & Speed',
      'title_hi': 'मैप लोडिंग एवं गति',
      'icon': Icons.map_rounded,
    },
    {
      'id': 'alerts',
      'title_en': 'SOS & Notification Alerts',
      'title_hi': 'SOS व सूचनाएं विलंब',
      'icon': Icons.notifications_active_rounded,
    },
    {
      'id': 'stability',
      'title_en': 'App Crashing or Freezing',
      'title_hi': 'ऐप क्रैश या फ्रीज होना',
      'icon': Icons.bug_report_rounded,
    },
    {
      'id': 'ui_confusion',
      'title_en': 'UI / Complex Navigation',
      'title_hi': 'डिज़ाइन / समझने में कठिनाई',
      'icon': Icons.touch_app_rounded,
    },
    {
      'id': 'other',
      'title_en': 'Other Improvement Suggestion',
      'title_hi': 'अन्य सुधार सुझाव',
      'icon': Icons.lightbulb_outline_rounded,
    },
  ];

  bool get _isMinorUser {
    try {
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      final role = box?.get('role')?.toString().toLowerCase() ?? 'user';
      return role == 'child';
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadPreviousRating();
  }

  void _loadPreviousRating() {
    try {
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      final savedRating = box?.get('user_feedback_rating', defaultValue: 0);
      if (savedRating is int && savedRating > 0) {
        setState(() {
          _rating = savedRating;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    // Child profile safeguard: Block attachments under DPDP Act Section 9
    if (_isMinorUser) {
      _showChildPrivacyNotice();
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _attachedScreenshot = File(picked.path);
          _attachedFileName = picked.name;
        });
      }
    } catch (e) {
      log('Error picking screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'इमेज चुनने में त्रुटि: $e'
                  : 'Error attaching screenshot: $e',
            ),
          ),
        );
      }
    }
  }

  void _removeScreenshot() {
    setState(() {
      _attachedScreenshot = null;
      _attachedFileName = null;
    });
  }

  void _showChildPrivacyNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: const Color(0xFF166534), size: 24.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi ? 'बाल सुरक्षा एवं गोपनीयता' : 'Child Privacy Safeguard',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isHindi
            ? 'DPDP अधिनियम 2023 की धारा 9 के तहत, नाबालिग (चाइल्ड) प्रोफाइल के लिए स्क्रीनशॉट या फोटो अपलोड प्रतिबंधित है ताकि बच्चों की व्यक्तिगत गोपनीयता सुरक्षित रहे।'
            : 'Under Section 9 of the DPDP Act 2023, image and screenshot attachments are strictly restricted for minor accounts to safeguard children from privacy exposure.',
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isHindi ? 'समझ गया' : 'Understood',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F3D38),
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// DPDP ACT AUTOMATIC PII SANITIZATION & STRIPPING
  /// -------------------------------------------------------------------------
  Map<String, dynamic> _sanitizeFeedbackPayload() {
    String rawText = _feedbackController.text.trim();

    // 1. Sanitize GPS latitude/longitude coordinates if accidentally pasted
    String sanitizedText = rawText.replaceAll(
      RegExp(r'-?\d{1,3}\.\d{4,8}'),
      '[COORDINATE_REDACTED]',
    );

    // 2. Sanitize Indian phone numbers (10 digits starting 6-9)
    sanitizedText = sanitizedText.replaceAll(
      RegExp(r'\b(?:\+91|0)?[6-9]\d{9}\b'),
      '[PHONE_NUMBER_REDACTED]',
    );

    // 3. Sanitize Auth tokens / passwords / bearer tokens
    sanitizedText = sanitizedText.replaceAll(
      RegExp(r'ey[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'),
      '[TOKEN_REDACTED]',
    );

    final payload = <String, dynamic>{
      'feedback_description': sanitizedText,
      'star_rating': _rating,
      'selected_issues': _selectedIssues.toList(),
      'is_minor_profile': _isMinorUser,
      'timestamp_iso8601': DateTime.now().toUtc().toIso8601String(),
      'retention_policy': '90_DAYS_AUTO_ANONYMIZED',
    };

    // Separate Opt-In Rule: Only attach diagnostics if explicitly checked
    if (_includeDiagnostics) {
      payload['technical_diagnostics'] = {
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'app_environment': 'Production',
        'telemetry_opted_in': true,
        'gps_coordinates': null, // Strictly null & stripped
        'contact_identifiers': null, // Strictly null & stripped
      };
    } else {
      payload['technical_diagnostics'] = null;
    }

    // Attachment rule
    if (_isMinorUser) {
      payload['attachment_file'] = null;
      payload['attachment_status'] = 'BLOCKED_MINOR_SAFEGUARD';
    } else {
      payload['attachment_file'] = _attachedScreenshot?.path;
      payload['attachment_status'] =
          _attachedScreenshot != null ? 'ATTACHED' : 'NONE';
    }

    return payload;
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();

    if (_rating == 0 && text.isEmpty && _selectedIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          content: Text(
            _isHindi
                ? 'कृपया रेटिंग दें या अपनी समस्या / सुझाव का विवरण लिखें!'
                : 'Please provide a rating or share your comments/issue details!',
            style: GoogleFonts.outfit(fontSize: 13.sp, color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Sanitize payload per DPDP rules
      final sanitizedPayload = _sanitizeFeedbackPayload();

      // 2. Save locally in Hive
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      if (box != null) {
        await box.put('user_feedback_rating', _rating);
        await box.put('user_feedback_text', sanitizedPayload['feedback_description']);
        await box.put('user_feedback_diagnostics_opt_in', _includeDiagnostics);
        await box.put('user_feedback_timestamp', sanitizedPayload['timestamp_iso8601']);
      }

      // 3. Log compliance event
      final complianceLedger = {
        'compliance_ledger_event': 'FEEDBACK_SUBMISSION_PROCESSED',
        'schema_version': 'TLO-DPDPA-FEEDBACK-V1.0',
        'is_minor_profile': _isMinorUser,
        'telemetry_attached': _includeDiagnostics,
        'pii_sanitized': true,
        'retention': '90_DAYS_ANONYMIZED',
      };
      log('COMPLIANCE LEDGER EVENT: ${jsonEncode(complianceLedger)}');
    } catch (e) {
      log('Error saving feedback: $e');
    }

    setState(() => _isSubmitting = false);

    // If 5 stars, prompt Google Play Store
    if (_rating == 5) {
      _launchPlayStore();
    }

    if (!mounted) return;
    _showSuccessDialog();
  }

  Future<void> _launchPlayStore() async {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.trackloved.app';
    try {
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
          side: BorderSide(color: brightGold.withValues(alpha: 0.6), width: 1.2),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brightGold.withValues(alpha: 0.15),
                  border: Border.all(color: brightGold),
                ),
                child: Icon(Icons.check_circle_rounded, color: brightGold, size: 36.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                _isHindi ? 'फीडबैक सफलतापूर्वक प्राप्त हुआ!' : 'Feedback Received!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _isHindi
                    ? 'आपकी प्रतिक्रिया हमारे सुरक्षा सिस्टम को बेहतर बनाएगी।\n\n🛡️ DPDP अनुपालन: आपका डेटा सुरक्षित है और समाधान के 90 दिनों के भीतर स्वतः अज्ञात (Anonymized) कर दिया जाएगा।'
                    : 'Thank you for helping us improve Track Loved Ones.\n\n🛡️ DPDP Compliance: Your submission has been sanitized of personal coordinates and will be permanently anonymized within 90 days of resolution.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 42.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightGold,
                    foregroundColor: const Color(0xFF072420),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    _isHindi ? 'पूर्ण, वापस जाएं' : 'Done, Go Back',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getSentimentInfo(int rating) {
    switch (rating) {
      case 1:
        return {
          'emoji': '😡',
          'label_en': 'Very Poor Experience',
          'label_hi': 'अत्यंत असंतोषजनक अनुभव',
          'color': const Color(0xFFFF5252),
          'sub_en': 'We are extremely sorry! Please let us know how we can fix this.',
          'sub_hi': 'हमें बेहद खेद है! कृपया बताएं कि हम इसे कैसे सुधारें।',
        };
      case 2:
        return {
          'emoji': '🙁',
          'label_en': 'Needs Improvement',
          'label_hi': 'सुधार की आवश्यकता है',
          'color': const Color(0xFFFF9800),
          'sub_en': 'Below expectations. We are committed to making it better.',
          'sub_hi': 'उम्मीद से कम। हम इसे बेहतर बनाने के लिए प्रतिबद्ध हैं।',
        };
      case 3:
        return {
          'emoji': '😐',
          'label_en': 'Average / Decent',
          'label_hi': 'सामान्य / संतोषजनक',
          'color': const Color(0xFFFFC107),
          'sub_en': 'Good, but there is definite room for enhancement.',
          'sub_hi': 'अच्छा, लेकिन इसमें और सुधार की गुंजाइश है।',
        };
      case 4:
        return {
          'emoji': '😊',
          'label_en': 'Very Good & Useful',
          'label_hi': 'काफ़ी अच्छा और उपयोगी',
          'color': const Color(0xFF66BB6A),
          'sub_en': 'Great experience! We are glad you find Track Loved helpful.',
          'sub_hi': 'शानदार अनुभव! हमें खुशी है कि ऐप आपके काम आ रहा है।',
        };
      case 5:
        return {
          'emoji': '🌟',
          'label_en': 'Exceptional! 5-Star Loved',
          'label_hi': 'शानदार! 5-स्टार उत्कृष्ट अनुभव',
          'color': brightGold,
          'sub_en': 'Thank you! You are helping protect more families.',
          'sub_hi': 'धन्यवाद! आपकी रेटिंग से अन्य परिवारों को सुरक्षित रहने में मदद मिलेगी।',
        };
      default:
        return {
          'emoji': '✨',
          'label_en': 'Tap stars to rate your experience',
          'label_hi': 'अनुभव साझा करने के लिए स्टार्स पर टैप करें',
          'color': Colors.white70,
          'sub_en': 'Your honest review guides our safety improvements.',
          'sub_hi': 'आपकी समीक्षा हमारे सुरक्षा सिस्टम को बेहतर बनाती है।',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentiment = _getSentimentInfo(_rating);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: darkBg,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Feedback & Bug Reporting',
        titleHi: 'फीडबैक एवं बग रिपोर्टिंग',
        isHindi: _isHindi,
        notificationCount: 0,
        onLanguageChanged: (val) {
          setState(() {
            _isHindi = val;
          });
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 540.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Hero Banner Card
                  _buildHeroHeader(sentiment),
                  SizedBox(height: 14.h),

                  // Rating Card with Interactive Stars
                  _buildInteractiveRatingCard(sentiment),
                  SizedBox(height: 14.h),

                  // Contextual View: 5 Stars Google Play Card OR Improvement Categories
                  if (_rating == 5)
                    _buildGooglePlayPromotionCard()
                  else if (_rating > 0 && _rating < 5)
                    _buildImprovementCategorySection(),

                  if (_rating > 0) SizedBox(height: 14.h),

                  // 📝 STEP 1: FEEDBACK DESCRIPTION
                  _buildStep1DescriptionCard(),
                  SizedBox(height: 14.h),

                  // 📎 STEP 2: OPTIONAL ATTACHMENTS (User Discretionary)
                  _buildStep2AttachmentsCard(),
                  SizedBox(height: 14.h),

                  // ⚙️ TECHNICAL DIAGNOSTICS LOGS (Optional Opt-In)
                  _buildStep3DiagnosticsCard(),
                  SizedBox(height: 14.h),

                  // ⚖️ FACILITATOR NOTICE & DATA LIMITATION (90-Day Anonymization)
                  _buildStep4FacilitatorNoticeCard(),
                  SizedBox(height: 18.h),

                  // Submit Action Button
                  _buildSubmitActionButton(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Map<String, dynamic> sentiment) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBg, surfaceDark],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: brandGold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brightGold.withValues(alpha: 0.15),
              border: Border.all(color: brightGold.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.bug_report_rounded,
              size: 24.sp,
              color: brightGold,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi
                      ? 'फीडबैक एवं बग रिपोर्टिंग'
                      : 'FEEDBACK & BUG REPORTING',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _isHindi
                      ? 'सुधार में हमारी सहायता करें। अपने विचार, नई सुविधाएं या तकनीकी समस्याएं नीचे साझा करें।'
                      : 'Help us improve. Please share your thoughts, feature requests, or report technical issues below.',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5.sp,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveRatingCard(Map<String, dynamic> sentiment) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (_rating > 0 ? brightGold : Colors.white24).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            _isHindi ? 'हमारे ऐप अनुभव को रेट करें' : 'How was your experience?',
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _isHindi
                ? (sentiment['sub_hi'] as String)
                : (sentiment['sub_en'] as String),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              color: Colors.white60,
            ),
          ),
          SizedBox(height: 12.h),

          // Star Row with interactive tap and scale
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= _rating;

              return InkWell(
                onTap: () {
                  setState(() {
                    _rating = starValue;
                  });
                },
                borderRadius: BorderRadius.circular(30.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.diagonal3Values(
                      isFilled ? 1.06 : 0.95,
                      isFilled ? 1.06 : 0.95,
                      1.0,
                    ),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36.sp,
                      color: isFilled ? starActive : Colors.white30,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 10.h),

          // Dynamic Sentiment Badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: (sentiment['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: (sentiment['color'] as Color).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sentiment['emoji'] as String,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(width: 6.w),
                Text(
                  _rating == 0
                      ? (_isHindi ? 'रेटिंग चुनें' : 'Select a rating')
                      : (_isHindi
                            ? (sentiment['label_hi'] as String)
                            : (sentiment['label_en'] as String)),
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: sentiment['color'] as Color,
                  ),
                ),
                if (_rating > 0) ...[
                  SizedBox(width: 6.w),
                  Text(
                    '($_rating/5)',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGooglePlayPromotionCard() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brightGold.withValues(alpha: 0.18), cardBg],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: brightGold.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: brightGold,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: surfaceDark,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? 'Google Play Store 5-स्टार रेटिंग'
                      : 'Official Google Play Store Review',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _isHindi
                ? 'हमे जानकर खुशी हुई कि आपको ऐप पसंद आया! नीचे दिए गए बटन पर टैप करके Google Play Store पर अपनी समीक्षा सबमिट करें।'
                : 'Your positive review helps other families discover Track Loved Ones for child & senior safety.',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCategorySection() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.orangeAccent,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? 'हम क्या बेहतर कर सकते हैं? (कारण चुनें)'
                      : 'What could be improved? (Select issues)',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: _issueCategories.map((item) {
              final id = item['id'] as String;
              final isSelected = _selectedIssues.contains(id);
              final title = _isHindi
                  ? (item['title_hi'] as String)
                  : (item['title_en'] as String);
              final icon = item['icon'] as IconData;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIssues.remove(id);
                    } else {
                      _selectedIssues.add(id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brightGold.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected ? brightGold : Colors.white24,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14.sp,
                        color: isSelected ? brightGold : Colors.white70,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? brightGold : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📝 STEP 1: FEEDBACK DESCRIPTION
  // ---------------------------------------------------------------------------
  Widget _buildStep1DescriptionCard() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: brandGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: brightGold, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? '📝 चरण 1: फीडबैक विवरण'
                      : '📝 STEP 1: FEEDBACK DESCRIPTION',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _isHindi ? '* अपने विचार यहां साझा करें:' : '* Share your comments here:',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            maxLength: 500,
            style: GoogleFonts.outfit(fontSize: 13.sp, color: Colors.white),
            decoration: InputDecoration(
              hintText: _isHindi
                  ? 'कृपया अपनी समस्या, सुझाव या बग का विवरण लिखें...'
                  : 'Describe your thoughts, feature requests, or technical bug here...',
              hintStyle: GoogleFonts.outfit(fontSize: 12.sp, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              counterStyle: GoogleFonts.outfit(fontSize: 11.sp, color: Colors.white38),
              contentPadding: EdgeInsets.all(12.r),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: brightGold, width: 1.4),
              ),
            ),
          ),
          SizedBox(height: 6.h),

          // Mandatory Privacy Warning Notice
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? '⚠️ चेतावनी: इस टेक्स्ट बॉक्स में क्रेडिट कार्ड नंबर, पासवर्ड, आधार या व्यक्तिगत पहचान संख्या साझा न करें।'
                        : '⚠️ Notice: Do not share credit card numbers, passwords, or personal identification numbers in this text box.',
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      color: Colors.amber.shade200,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📎 STEP 2: OPTIONAL ATTACHMENTS (User Discretionary)
  // ---------------------------------------------------------------------------
  Widget _buildStep2AttachmentsCard() {
    final isMinor = _isMinorUser;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: brandGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, color: brightGold, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? '📎 चरण 2: वैकल्पिक संलग्नक (उपयोगकर्ता विवेक)'
                      : '📎 STEP 2: OPTIONAL ATTACHMENTS (User Discretionary)',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Attachment Action Area
          if (isMinor)
            // Child Safeguard Banner: Disabled
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_person_rounded, color: Colors.redAccent, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? '🛡️ बाल सुरक्षा (DPDP धारा 9): नाबालिग खातों के लिए स्क्रीनशॉट अपलोडिंग स्वतः अक्षम है।'
                          : '🛡️ Minor Privacy Safeguard: Screenshot upload is restricted on child accounts under DPDP Act Section 9.',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5.sp,
                        color: Colors.red.shade200,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (_attachedScreenshot == null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brightGold),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.camera_alt_rounded, color: brightGold, size: 18.sp),
                label: Text(
                  _isHindi
                      ? '📸 स्क्रीनशॉट / इमेज संलग्न करें'
                      : '📸 Attach Screenshot / Image File',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                  ),
                ),
                onPressed: _pickScreenshot,
              )
            else
              // Attached Preview Card
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: brightGold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Image.file(
                        _attachedScreenshot!,
                        width: 44.w,
                        height: 44.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachedFileName ?? 'Screenshot.jpg',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _isHindi ? 'छवि संलग्न है' : 'Image attached',
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: Colors.redAccent,
                        size: 20.sp,
                      ),
                      tooltip: _isHindi ? 'हटाएं' : 'Remove',
                      onPressed: _removeScreenshot,
                    ),
                  ],
                ),
              ),
          ],
          SizedBox(height: 10.h),

          // Privacy Safeguard text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 3.h, right: 6.w),
                child: Icon(Icons.shield_outlined, size: 14.sp, color: Colors.white60),
              ),
              Expanded(
                child: Text(
                  _isHindi
                      ? '• गोपनीयता सुरक्षा: अपलोड करने से पहले सुनिश्चित करें कि स्क्रीनशॉट में कोई फोन नंबर, लाइव मैप या गोपनीय फाइल दिखाई न दे।'
                      : '• Privacy Safeguard: Ensure no visible phone numbers, active maps, or confidential files are captured in your screenshot before uploading.',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: Colors.white60,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⚙️ TECHNICAL DIAGNOSTICS LOGS (Optional Opt-In)
  // ---------------------------------------------------------------------------
  Widget _buildStep3DiagnosticsCard() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: brandGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: brightGold, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? '⚙️ तकनीकी डायग्नोस्टिक लॉग्स (वैकल्पिक Opt-In)'
                      : '⚙️ TECHNICAL DIAGNOSTICS LOGS (Optional Opt-In)',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: brightGold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _isHindi
                ? 'सॉफ्टवेयर क्रैश को प्रभावी रूप से ठीक करने के लिए हम एक बुनियादी तकनीकी लॉग फ़ाइल संकलित करते हैं:'
                : 'To fix software crashes effectively, we compile a basic technical log file.',
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          SizedBox(height: 6.h),
          _buildDiagnosticsBullet(
            _isHindi
                ? '• शामिल डेटा: डिवाइस मॉडल, OS संस्करण, ऐप प्रदर्शन व लेटेंसी पैरामीटर।'
                : '• Data Inside: Device model, OS version, app performance latency parameters.',
          ),
          SizedBox(height: 4.h),
          _buildDiagnosticsBullet(
            _isHindi
                ? '• गोपनीयता गारंटी: यह लॉग आपके रीयल-टाइम GPS निर्देशांक और संपर्क पहचानकर्ताओं से पूरी तरह मुक्त (stripped) है।'
                : '• Privacy Guarantee: This log is strictly stripped of your real-time GPS coordinates and contact profile identifiers.',
          ),
          SizedBox(height: 10.h),

          // Separate Opt-In Checkbox (Unchecked by default)
          InkWell(
            onTap: () {
              setState(() {
                _includeDiagnostics = !_includeDiagnostics;
              });
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _includeDiagnostics
                    ? brightGold.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _includeDiagnostics
                      ? brightGold
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: Checkbox(
                      value: _includeDiagnostics,
                      activeColor: brightGold,
                      checkColor: const Color(0xFF072420),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _includeDiagnostics = val ?? false;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHindi
                              ? 'इस फीडबैक के साथ तकनीकी सिस्टम डायग्नोस्टिक लॉग शामिल करें।'
                              : 'Include technical system diagnostic logs with this feedback.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _isHindi
                              ? '(डिफ़ॉल्ट रूप से अनचेक रहता है। लॉग साझा न करने के लिए खाली छोड़ें)।'
                              : '(Unchecked by default. Leave blank to skip technical log sharing).',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5.sp,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 3.h, right: 6.w),
          child: Icon(Icons.circle, size: 5.sp, color: brightGold),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: Colors.white60,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ⚖️ FACILITATOR NOTICE & DATA LIMITATION (90-Day Anonymization)
  // ---------------------------------------------------------------------------
  Widget _buildStep4FacilitatorNoticeCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF002E29),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF86EFAC).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                color: const Color(0xFF86EFAC),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? '⚖️ फैसिलिटेटर सूचना एवं डेटा सीमा'
                      : '⚖️ FACILITATOR NOTICE & DATA LIMITATION',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF86EFAC),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _isHindi
                ? 'Track Loved Ones App एक प्रौद्योगिकी मंच के रूप में कार्य करता है। फीडबैक सबमिट करना कानूनी सलाह, डेटा उल्लंघन फाइलिंग या रोजगार प्रश्न का गठन नहीं करता है। आपका फीडबैक डेटा केवल उपयोगिता में सुधार के लिए संसाधित किया जाता है और समस्या के समाधान के 90 दिनों के भीतर स्थायी रूप से अज्ञात (Anonymized) कर दिया जाएगा।'
                : 'Track Loved Ones App acts as a technology venue. Submitting feedback does not constitute legal advice, a data breach filing, or an employment query. Your feedback data is processed strictly to improve utility and will be permanently anonymized within 90 days of issue resolution.',
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildSubmitActionButton() {
    final isFiveStars = _rating == 5;
    final buttonText = isFiveStars
        ? (_isHindi
              ? 'Google Play Store पर 5-स्टार दें'
              : 'Rate 5 Stars on Google Play Store')
        : (_isHindi ? 'फीडबैक सबमिट करें' : 'Submit Feedback');
    final buttonIcon = isFiveStars ? Icons.star_rounded : Icons.send_rounded;

    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: isFiveStars
              ? [brightGold, const Color(0xFFC5A038)]
              : [const Color(0xFF0F3D38), const Color(0xFF072420)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isFiveStars ? brightGold : cardBg).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isFiveStars ? Colors.white70 : brightGold.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        onPressed: _isSubmitting ? null : _submitFeedback,
        child: _isSubmitting
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    buttonIcon,
                    size: 18.sp,
                    color: isFiveStars ? const Color(0xFF072420) : brightGold,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isFiveStars ? const Color(0xFF072420) : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
