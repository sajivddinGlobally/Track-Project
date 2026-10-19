import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FeedbackRatingScreen extends StatefulWidget {
  const FeedbackRatingScreen({super.key});

  @override
  State<FeedbackRatingScreen> createState() => _FeedbackRatingScreenState();
}

class _FeedbackRatingScreenState extends State<FeedbackRatingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _feedbackController = TextEditingController();

  int _rating = 0;
  String? _selectedIssue;
  bool _isHindi = false;

  final List<String> _issues = [
    'Location tracking delay (Lag)',
    'Inaccurate GPS coordinates',
    'High battery consumption',
    'App crashing or freezing',
    'Difficult to use / UI confusion',
    'Other issue',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a star rating first!',
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
      );
      return;
    }

    if (_rating < 5 &&
        _selectedIssue == null &&
        _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select or specify what did not work for you.',
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          _isHindi ? 'धन्यवाद!' : 'Thank You!',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          _rating == 5
              ? (_isHindi
                    ? 'Google Play पर रेट करने के लिए रीडायरेक्ट किया जा रहा है...'
                    : 'Redirecting to Google Play Store rating...')
              : (_isHindi
                    ? 'आपका फीडबैक दर्ज कर लिया गया है। हम इसे सुधारने पर काम कर रहे हैं।'
                    : 'Your feedback has been recorded. We appreciate your insights to improve the app.'),
          style: TextStyle(fontSize: 13.5.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Return to Search Loved Ones Screen
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: const Color(0xFF0B4F4A),
                fontSize: 14.sp,
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
    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4F4A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 24.sp),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _isHindi ? 'फीडबैक और रेटिंग' : 'Feedback & Rating',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 450.w),
            padding: EdgeInsets.all(20.0.r),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 64.sp,
                    color: const Color(0xFFFBC02D),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _isHindi
                        ? 'आप हमारे अनुभव को कैसे रेट करेंगे?'
                        : 'How was your location tracking experience?',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Help us serve you better with your honest feedback.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      int starValue = index + 1;
                      return IconButton(
                        iconSize: 40.sp,
                        icon: Icon(
                          starValue <= _rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFBC02D),
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = starValue;
                            if (_rating == 5) _selectedIssue = null;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _rating == 0
                        ? 'Tap a star to rate'
                        : '$_rating out of 5 stars',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (_rating > 0 && _rating < 5) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFDCDFE4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What did not work well for you?',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Please select the primary reason so we can fix it:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ..._issues.map((issue) {
                            return RadioListTile<String>(
                              title: Text(
                                issue,
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              value: issue,
                              groupValue: _selectedIssue,
                              activeColor: const Color(0xFF0B4F4A),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (val) {
                                setState(() {
                                  _selectedIssue = val;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: _rating < 5 && _rating > 0
                          ? 'Please provide any additional details...'
                          : 'Write your comments or suggestions here...',
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black45,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFFC5A038),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4F4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      onPressed: _submitFeedback,
                      child: Text(
                        _rating == 5
                            ? 'Rate on Google Play Store'
                            : 'Submit Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
