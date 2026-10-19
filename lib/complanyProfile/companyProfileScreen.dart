import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';

// -----------------------------------------------------------------
// SCREEN: Company Profile & Verification (GST, PAN, Type)
// -----------------------------------------------------------------
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String _selectedCompanyType = 'Private Limited';
  final List<String> _companyTypes = [
    'Private Limited',
    'Proprietorship',
    'Partnership',
    'Limited Liability Partnership (LLP)',
    'Public Limited / Corporate',
    'NGO / Trust',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Company Profile Saved!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Your corporate KYC details (GST/PAN) have been securely saved independently of your personal account profile.',
            style: TextStyle(
              fontSize: 13.5.sp,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/post-job');
              },
              child: Text(
                'Proceed to Post Job',
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
      key: _scaffoldKey,
      drawer: const AppDrawer(isHindi: false),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4F4A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 24.sp),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Company Profile & KYC',
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
            constraints: BoxConstraints(maxWidth: 600.w),
            padding: EdgeInsets.all(20.0.r),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Establish Corporate Identity',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'This profile is strictly for organization verification and job posting compliance.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                    ),
                    SizedBox(height: 20.h),
                    TextFormField(
                      controller: _companyNameController,
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                      decoration: _inputDecoration(
                        'Registered Company Name *',
                        hint: 'e.g., SwiftLogistics India Pvt Ltd',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter company name'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCompanyType,
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                      decoration: _inputDecoration('Company Type *'),
                      items: _companyTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCompanyType = val!),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gstController,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                            decoration: _inputDecoration(
                              'GST Number *',
                              hint: '22AAAAA0000A1Z5',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter GST number'
                                : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            controller: _panController,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                            decoration: _inputDecoration(
                              'Company PAN *',
                              hint: 'AAAAA0000A',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter PAN number'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                      decoration: _inputDecoration(
                        'Registered Corporate Address *',
                        hint: 'Enter street address, city, state',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter address'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: _websiteController,
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                      decoration: _inputDecoration(
                        'Official Website (Optional)',
                        hint: 'https://www.company.com',
                      ),
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
                        onPressed: _saveProfile,
                        child: Text(
                          'Save Company Details',
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13.5.sp, color: Colors.black54),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black45),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF0B4F4A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
