import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
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

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadPreviousRating();
  }

  void _loadPreviousRating() {
    try {
      final box = Hive.box('userdata');
      final savedRating = box.get('user_feedback_rating', defaultValue: 0);
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

  Map<String, dynamic> _getSentimentInfo(int rating) {
    switch (rating) {
      case 1:
        return {
          'emoji': '😡',
          'label_en': 'Very Poor Experience',
          'label_hi': 'अत्यंत असंतोषजनक अनुभव',
          'color': const Color(0xFFFF5252),
          'sub_en': 'We are extremely sorry! Please let us know how we can fix this for you.',
          'sub_hi': 'हमें बेहद खेद है! कृपया बताएं कि हम इसे आपके लिए कैसे सुधारें।',
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
          'sub_en': 'Thank you! You are helping protect more families with this rating.',
          'sub_hi': 'धन्यवाद! आपकी रेटिंग से अन्य परिवारों को सुरक्षित रहने में मदद मिलेगी।',
        };
      default:
        return {
          'emoji': '✨',
          'label_en': 'Tap stars to rate your experience',
          'label_hi': 'अनुभव साझा करने के लिए स्टार्स पर टैप करें',
          'color': Colors.white70,
          'sub_en': 'Your honest review guides our safety and tracking improvements.',
          'sub_hi': 'आपकी समीक्षा हमारे सुरक्षा और ट्रैकिंग सिस्टम को बेहतर बनाती है।',
        };
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          content: Text(
            _isHindi
                ? 'कृपया पहले 1 से 5 स्टार रेटिंग चुनें!'
                : 'Please select a star rating between 1 and 5 first!',
            style: GoogleFonts.outfit(fontSize: 13.sp, color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (_rating < 5 && _selectedIssues.isEmpty && _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          content: Text(
            _isHindi
                ? 'कृपया समस्या का कारण चुनें या विवरण लिखें।'
                : 'Please select an issue category or write details to help us improve.',
            style: GoogleFonts.outfit(fontSize: 13.sp, color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Save feedback in Hive locally
      final box = Hive.box('userdata');
      await box.put('user_feedback_rating', _rating);
      await box.put('user_feedback_text', _feedbackController.text.trim());
      await box.put('user_feedback_issues', _selectedIssues.toList());
      await box.put('user_feedback_timestamp', DateTime.now().toIso8601String());
    } catch (_) {}

    setState(() => _isSubmitting = false);

    // If 5 stars, offer to launch Google Play Store
    if (_rating == 5) {
      _launchPlayStore();
    }

    if (!mounted) return;
    _showSuccessDialog();
  }

  Future<void> _launchPlayStore() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.trackloved.app';
    const marketUrl = 'market://details?id=com.trackloved.app';
    try {
      final marketUri = Uri.parse(marketUrl);
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
      final webUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showSuccessDialog() {
    final sentiment = _getSentimentInfo(_rating);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: brandGold.withValues(alpha: 0.6), width: 1.5),
        ),
        contentPadding: EdgeInsets.all(22.r),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [brightGold, Color(0xFF8B6B18)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: brightGold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  sentiment['emoji'] as String,
                  style: TextStyle(fontSize: 32.sp),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _isHindi ? 'फीडबैक प्राप्त हुआ!' : 'Thank You for Your Feedback!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              _rating == 5
                  ? (_isHindi
                        ? 'Google Play Store पर आपकी 5-स्टार समीक्षा से अन्य परिवारों को सुरक्षित रहने में मदद मिलेगी। धन्यवाद!'
                        : 'Your 5-star rating on Google Play Store encourages our team and helps more families discover loved ones safety.')
                  : (_isHindi
                        ? 'आपकी प्रतिक्रिया हमारे डेवलपमेंट और सुरक्षा टीम को भेज दी गई है। हम इसे प्राथमिकता पर हल करेंगे।'
                        : 'Your valuable suggestions have been recorded and sent to our product engineering team. We appreciate your insights!'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                color: Colors.white70,
                height: 1.45,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
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
                  _isHindi ? 'ठीक है, वापस जाएं' : 'Done, Go Back',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentiment = _getSentimentInfo(_rating);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: darkBg,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Feedback & Rating',
        titleHi: 'फीडबैक और रेटिंग',
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
              constraints: BoxConstraints(maxWidth: 520.w),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Hero Banner Card
                  _buildHeroHeader(sentiment),
                  SizedBox(height: 18.h),

                  // Rating Card with Interactive Stars
                  _buildInteractiveRatingCard(sentiment),
                  SizedBox(height: 18.h),

                  // Contextual View: 5 Stars Google Play Card OR Improvement Categories
                  if (_rating == 5)
                    _buildGooglePlayPromotionCard()
                  else if (_rating > 0 && _rating < 5)
                    _buildImprovementCategorySection(),

                  SizedBox(height: 16.h),

                  // Comments & Suggestions Box
                  _buildFeedbackInputCard(),
                  SizedBox(height: 14.h),

                  // Trust & Privacy Note
                  _buildPrivacyGuaranteeBadge(),
                  SizedBox(height: 22.h),

                  // Submit / Google Play Store Action Button
                  _buildSubmitActionButton(),
                  SizedBox(height: 30.h),
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBg,
            surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: brandGold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brightGold.withValues(alpha: 0.15),
              border: Border.all(color: brightGold.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.stars_rounded,
              size: 28.sp,
              color: brightGold,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi ? 'आपकी राय महत्वपूर्ण है' : 'Your Review Protects Families',
                  style: GoogleFonts.outfit(
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _isHindi
                      ? 'ट्रैक लव्ड को सुरक्षित और विश्वसनीय बनाने के लिए अपना ईमानदार फीडबैक दें।'
                      : 'Help us refine real-time safety, accurate maps, and peace of mind.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    height: 1.35,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: (_rating > 0 ? brightGold : Colors.white24).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _isHindi
                ? 'हमारे ऐप अनुभव को रेट करें'
                : 'How was your experience?',
            style: GoogleFonts.outfit(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _isHindi
                ? (sentiment['sub_hi'] as String)
                : (sentiment['sub_en'] as String),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.5.sp,
              color: Colors.white60,
            ),
          ),
          SizedBox(height: 16.h),

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
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.diagonal3Values(
                      isFilled ? 1.08 : 0.95,
                      isFilled ? 1.08 : 0.95,
                      1.0,
                    ),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 42.sp,
                      color: isFilled ? starActive : Colors.white30,
                      shadows: isFilled
                          ? [
                              Shadow(
                                color: starActive.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 14.h),

          // Dynamic Sentiment Badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
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
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(width: 8.w),
                Text(
                  _rating == 0
                      ? (_isHindi ? 'रेटिंग चुनें' : 'Select a rating')
                      : (_isHindi
                            ? (sentiment['label_hi'] as String)
                            : (sentiment['label_en'] as String)),
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: sentiment['color'] as Color,
                  ),
                ),
                if (_rating > 0) ...[
                  SizedBox(width: 6.w),
                  Text(
                    '($_rating/5)',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brightGold.withValues(alpha: 0.18),
            cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: brightGold.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: brightGold,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: surfaceDark,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi
                          ? 'Google Play Store 5-स्टार रेटिंग'
                          : 'Official Google Play Store Review',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.bold,
                        color: brightGold,
                      ),
                    ),
                    Text(
                      _isHindi
                          ? 'दुनिया भर के परिवारों के लिए आपका समर्थन'
                          : 'Public recommendation for community safety',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _isHindi
                ? 'हमे यह जानकर बेहद खुशी हुई कि आपको ऐप पसंद आया! नीचे दिए गए बटन पर टैप करके Google Play Store पर अपनी 5-स्टार रेटिंग सबमिट करें।'
                : 'Your positive review helps us rank better on the Google Play Store so more families can keep their children and seniors safe.',
            style: GoogleFonts.outfit(
              fontSize: 12.5.sp,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCategorySection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.4),
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
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? 'हम क्या बेहतर कर सकते हैं? (कारण चुनें)'
                      : 'What could be improved? (Select issues)',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
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
                borderRadius: BorderRadius.circular(10.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brightGold.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
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
                        size: 15.sp,
                        color: isSelected ? brightGold : Colors.white70,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildFeedbackInputCard() {
    final hint = _rating == 5
        ? (_isHindi
              ? 'आपको कौन सी सुविधा सबसे अच्छी लगी? (वैकल्पिक टिप्पणी)...'
              : 'What feature did you like the most? (Optional praise or thoughts)...')
        : (_isHindi
              ? 'कृपया समस्या का विवरण दें ताकि हमारी टेक्निकल टीम इसे तुरंत हल कर सके...'
              : 'Please write specific details or suggestions to help us fix this...');

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: brandGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: brightGold,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                _isHindi ? 'अतिरिक्त टिप्पणी / सुझाव' : 'Comments & Detailed Notes',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            maxLength: 500,
            style: GoogleFonts.outfit(
              fontSize: 13.5.sp,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 12.5.sp,
                color: Colors.white38,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              counterStyle: GoogleFonts.outfit(
                fontSize: 11.sp,
                color: Colors.white38,
              ),
              contentPadding: EdgeInsets.all(14.r),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: brightGold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyGuaranteeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: const Color(0xFF00E676),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _isHindi
                  ? 'आपकी प्रतिक्रिया सीधी सुरक्षा और इंजीनियरिंग टीम द्वारा जांची जाती है।'
                  : 'Your feedback is private and directly reviewed by our security & core team.',
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitActionButton() {
    final isFiveStars = _rating == 5;
    final buttonText = isFiveStars
        ? (_isHindi ? 'Google Play Store पर 5-स्टार दें' : 'Rate 5 Stars on Google Play Store')
        : (_isHindi ? 'फीडबैक सबमिट करें' : 'Submit Feedback');
    final buttonIcon = isFiveStars ? Icons.star_rounded : Icons.send_rounded;

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        gradient: LinearGradient(
          colors: isFiveStars
              ? [brightGold, const Color(0xFFC5A038)]
              : [const Color(0xFF0F3D38), const Color(0xFF072420)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isFiveStars ? brightGold : cardBg).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        onPressed: _isSubmitting ? null : _submitFeedback,
        child: _isSubmitting
            ? SizedBox(
                width: 22.r,
                height: 22.r,
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
                    size: 20.sp,
                    color: isFiveStars ? const Color(0xFF072420) : brightGold,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
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
