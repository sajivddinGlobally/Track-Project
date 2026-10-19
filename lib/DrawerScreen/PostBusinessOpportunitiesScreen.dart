import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';

class PostBusinessOpportunitiesScreen extends StatefulWidget {
  const PostBusinessOpportunitiesScreen({super.key});

  @override
  State<PostBusinessOpportunitiesScreen> createState() =>
      PostBusinessOpportunitiesScreenState();
}

class PostBusinessOpportunitiesScreenState
    extends State<PostBusinessOpportunitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pincodeInputController = TextEditingController();
  final TextEditingController _annualCtcController = TextEditingController();
  final TextEditingController _perksController = TextEditingController();
  final TextEditingController _reimbursementsController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _isHindi = false;

  String? _selectedJobType;
  String? _selectedLevel;

  final List<String> _jobTypes = [
    'Full-Time',
    'Part-Time',
    'Contract / Project-Based',
    'Remote / WFH',
    'Internship',
  ];

  final List<String> _jobLevels = ['Frontline', 'Mid-Level', 'Senior'];

  final List<String> _selectedPincodes = [];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _locationController.dispose();
    _pincodeInputController.dispose();
    _annualCtcController.dispose();
    _perksController.dispose();
    _reimbursementsController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _addPinCode() {
    final pin = _pincodeInputController.text.trim();

    if (pin.length == 6 && !_selectedPincodes.contains(pin)) {
      setState(() {
        _selectedPincodes.add(pin);
        _pincodeInputController.clear();
      });
    }
  }

  void _submitJob() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPincodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one target pin code.'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Job Opportunity Posted!'),
          content: Text(
            'Your listing targeting ${_selectedPincodes.length} pin code(s) is now active.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                  context,
                  '/business-opportunities',
                );
              },
              child: const Text(
                'View Explore Feed',
                style: TextStyle(
                  color: Color(0xFF0B4F4A),
                  fontWeight: FontWeight.bold,
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
        titleEn: 'Post Business Opportunities',
        titleHi: 'नौकरी का अवसर पोस्ट करें',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
        onNotificationPressed: () {},
      ),

      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    'Create Job Listing',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Define compensation, levels, and specific target areas.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader('1. Role & Seniority Level'),
                  SizedBox(height: 10.h),

                  // Job Title
                  _buildTextField(
                    controller: _jobTitleController,
                    label: 'Job Title / Designation *',
                    validatorMsg: 'Enter job title',
                    icon: Icons.work_outline,
                  ),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedJobType,
                    decoration: _inputDecoration(
                      'Employment Type *',
                      icon: Icons.business_center_outlined,
                    ),
                    dropdownColor: const Color(0xFF003A35),
                    items: _jobTypes.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedJobType = v;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp),
                    decoration: _inputDecoration(
                      'Hierarchy Level *',
                      icon: Icons.leaderboard_outlined,
                    ),
                    dropdownColor: const Color(0xFF003A35),
                    items: _jobLevels.map((l) {
                      return DropdownMenuItem<String>(
                        value: l,
                        child: Text(
                          l,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedLevel = v;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader('2. Location & Target Pin Codes'),
                  SizedBox(height: 10.h),
                  // Location
                  _buildTextField(
                    controller: _locationController,
                    label: 'Base City / Location *',
                    validatorMsg: 'Enter location',
                    icon: Icons.location_on_outlined,
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _pincodeInputController,
                          label: 'Add Target Pin Code',
                          validatorMsg: 'Enter pin code',
                          keyboardType: TextInputType.number,
                          icon: Icons.pin_drop_outlined,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      SizedBox(
                        height: 50.h,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B4F4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: _addPinCode,
                          icon: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          label: Text(
                            'Add Pin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    children: _selectedPincodes.map((pin) {
                      return Chip(
                        label: Text(pin, style: TextStyle(fontSize: 12.sp)),
                        backgroundColor: const Color(0xFFE0F2F1),
                        deleteIcon: Icon(Icons.close, size: 14.sp),
                        onDeleted: () {
                          setState(() {
                            _selectedPincodes.remove(pin);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader('3. Annual CTC, Perks & Reimbursements'),
                  SizedBox(height: 10.h),
                  // Annual CTC
                  _buildTextField(
                    controller: _annualCtcController,
                    label: 'Annual CTC Package *',
                    validatorMsg: 'Enter CTC details',
                    icon: Icons.currency_rupee,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _perksController,
                          label: 'Perks & Benefits',
                          validatorMsg: 'Enter perks',
                          icon: Icons.card_giftcard_outlined,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _reimbursementsController,
                          label: 'Reimbursements',
                          validatorMsg: 'Enter reimbursements',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader('4. Responsibilities & Application Details'),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textAlign: TextAlign.justify,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      isDense: true,
                      labelText: 'Job Description & Requirements *',
                      labelStyle: TextStyle(
                        color: Colors.white60,
                        fontSize: 15.5.sp,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Color(0xFFC5A038)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    // validator: (value) {
                    //   if (value == null || value.trim().isEmpty) {
                    //     return 'Enter job description';
                    //   }
                    //   return null;
                    // },
                  ),
                  SizedBox(height: 16.h),
                  // Contact
                  _buildTextField(
                    controller: _contactController,
                    label: 'Application Contact (Email / Phone) *',
                    validatorMsg: 'Enter application contact',
                    icon: Icons.contact_phone_outlined,
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
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // ============================================================
  // REUSABLE TEXT FIELD WIDGET
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validatorMsg,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 15.5.sp),
        prefixIcon: Icon(icon, color: Colors.white60, size: 24.sp),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFC5A038)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMsg;
        }
        return null;
      },
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
      hintStyle: TextStyle(color: Colors.white60, fontSize: 13.sp),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white60, size: 22.sp)
          : null,
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
    );
  }
}
