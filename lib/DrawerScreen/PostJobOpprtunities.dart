import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';

class PostJobOpportunitiesScreen extends StatefulWidget {
  const PostJobOpportunitiesScreen({super.key});

  @override
  State<PostJobOpportunitiesScreen> createState() =>
      _PostJobOpportunitiesScreenState();
}

class _PostJobOpportunitiesScreenState
    extends State<PostJobOpportunitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  String _selectedJobType = 'Full-Time';
  bool _isHindi = false;

  final List<String> _jobTypes = [
    'Full-Time',
    'Part-Time',
    'Contract / Project-Based',
    'Remote / Work from Home',
    'Internship',
  ];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _employerController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _submitJob() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            _isHindi ? 'सफलता!' : 'Job Posted Successfully!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            _isHindi
                ? 'आपका नौकरी का अवसर लाइव कर दिया गया है।'
                : 'Your job opportunity listing has been posted. Local applicants can now view and apply.',
            style: TextStyle(
              fontSize: 13.5.sp,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(
                  context,
                  '/business-opportunities',
                );
              },
              child: Text(
                'Back to Home',
                style: TextStyle(
                  color: const Color(0xFF0B4F4A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Post Job Opportunities',
        titleHi: 'नौकरी के अवसर पोस्ट करें',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
        onNotificationPressed: () {},
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600.w),
            padding: EdgeInsets.all(20.0.r),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFF0B4F4A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_membership,
                            color: const Color(0xFF0B4F4A),
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _isHindi
                                  ? 'यह एक सशुल्क सदस्यता सुविधा है, जो सीमित समय के लिए पूरी तरह से निःशुल्क उपलब्ध है।'
                                  : 'Paid Subscription Feature — Currently Available FREE for a Limited Period!',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B4F4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Create a Job Listing',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Post job openings to connect with qualified professionals in your network area.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 20.h),
                    _buildTextField(
                      controller: _jobTitleController,
                      label: 'Job Title / Designation *',
                      hint:
                          'e.g., Senior Operations Manager / Delivery Executive',
                      validatorMsg: 'Please enter a job title',
                      icon: Icons.work_outline,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _employerController,
                      label: 'Company / Employer Name *',
                      hint: 'e.g., SwiftLogistics Express',
                      validatorMsg: 'Please enter company name',
                      icon: Icons.business,
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedJobType,
                      dropdownColor: const Color(0xFF141A19),
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      iconEnabledColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Employment Type *',
                        labelStyle: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.5.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: Colors.white60,
                          size: 22.sp,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
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
                          ),
                        ),
                      ),
                      items: _jobTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedJobType = val);
                        }
                      },
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _locationController,
                            label: 'Job Location *',
                            hint: 'e.g., Faridabad / Remote',
                            validatorMsg: 'Enter location',
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _salaryController,
                            label: 'Salary / Compensation *',
                            hint: 'e.g., ₹25,000 - ₹40,000 / month',
                            validatorMsg: 'Enter compensation details',
                            icon: Icons.currency_rupee,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Job Description & Requirements *',
                      hint:
                          'Outline key responsibilities, shift timing, and skills required...',
                      validatorMsg: 'Please provide description',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _contactEmailController,
                      label: 'Application Email or Phone *',
                      hint: 'hr@company.com or +91 98765 43210',
                      validatorMsg: 'Enter contact channel',
                      icon: Icons.contact_mail_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 30.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4F4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        onPressed: _submitJob,
                        child: Text(
                          'Publish Job Listing',
                          style: TextStyle(
                            color: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String validatorMsg,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMsg;
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.white60),
        prefixIcon: Icon(
          icon ?? Icons.work_outline,
          color: Colors.white60,
          size: 22.sp,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
          borderSide: const BorderSide(color: Color(0xFFC5A038)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
