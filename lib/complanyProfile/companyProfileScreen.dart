import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/PostJobOpprtunities.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/BusinessProfileBodyModel.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isHindi = false;
  bool _isLoading = false;
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
  void initState() {
    super.initState();
    final box = Hive.box('userdata');
    _companyNameController.text = box.get('companyName', defaultValue: '');
    _gstController.text = box.get('companyGst', defaultValue: '');
    _panController.text = box.get('companyPan', defaultValue: '');
    _addressController.text = box.get('companyAddress', defaultValue: '');
    _websiteController.text = box.get('companyWebsite', defaultValue: '');
    final savedType = box.get('companyType');
    if (savedType != null && _companyTypes.contains(savedType)) {
      _selectedCompanyType = savedType;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final body = BusinessProfileBodyModel(
          registeredCompanyName: _companyNameController.text.trim(),
          companyType: _selectedCompanyType,
          gstNumber: _gstController.text.trim().toUpperCase(),
          companyPanNumber: _panController.text.trim().toUpperCase(),
          registeredCorporateAddress: _addressController.text.trim(),
          officialWebsite: _websiteController.text.trim().isNotEmpty
              ? _websiteController.text.trim()
              : null,
        );

        final authService = ref.read(authServiceProvider);
        final response = await authService.saveBusinessProfileData(body);

        // Persist locally in Hive
        final box = Hive.box('userdata');
        await box.put('isCompanyProfileComplete', true);
        await box.put('companyName', _companyNameController.text.trim());
        await box.put('companyType', _selectedCompanyType);
        await box.put('companyGst', _gstController.text.trim().toUpperCase());
        await box.put('companyPan', _panController.text.trim().toUpperCase());
        await box.put('companyAddress', _addressController.text.trim());
        await box.put('companyWebsite', _websiteController.text.trim());

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF0B4F4A),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi ? 'विवरण सुरक्षित!' : 'Company Profile Saved!',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              response.message ??
                  (_isHindi
                      ? 'आपकी कंपनी और कॉर्पोरेट KYC (GST/PAN) विवरण सफलतापूर्वक सुरक्षित कर दिए गए हैं।'
                      : 'Your corporate KYC details (GST/PAN) have been securely saved.'),
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
                  Navigator.pop(context, true);
                },
                child: Text(
                  _isHindi ? 'पूर्ण' : 'Done',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4F4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostJobOpportunitiesScreen(),
                    ),
                  );
                },
                child: Text(
                  _isHindi ? 'नौकरी पोस्ट पर जाएं' : 'Proceed to Post Job',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        log(e.toString());
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Company Profile & KYC',
        titleHi: 'कंपनी प्रोफ़ाइल और केवाईसी',
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Info Banner Card
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF0B4F4A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: const Color(0xFF0B4F4A),
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              _isHindi
                                  ? 'कॉर्पोरेट सत्यापन: अवसर या नौकरी पोस्ट करने के लिए अपनी कंपनी का विवरण और वैध GST/PAN भरना अनिवार्य है।'
                                  : 'Corporate KYC: Complete your company profile with valid GST/PAN to enable job & opportunity postings.',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B4F4A),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Title Header
                    Text(
                      _isHindi
                          ? 'कॉर्पोरेट पहचान स्थापित करें'
                          : 'Establish Corporate Identity',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _isHindi
                          ? 'यह प्रोफ़ाइल संगठन सत्यापन और व्यावसायिक अनुपालन के लिए आवश्यक है।'
                          : 'This profile is strictly for organization verification and job posting compliance.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 22.h),

                    // Section 1: Organization Details
                    _sectionHeader(
                      _isHindi
                          ? '1. संगठन की जानकारी'
                          : '1. Organization Details',
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _companyNameController,
                      label: _isHindi
                          ? 'पंजीकृत कंपनी का नाम *'
                          : 'Registered Company Name *',
                      hint: 'e.g., SwiftLogistics India Pvt Ltd',
                      validatorMsg: _isHindi
                          ? 'कृपया कंपनी का नाम दर्ज करें'
                          : 'Enter registered company name',
                      icon: Icons.business,
                    ),
                    SizedBox(height: 14.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCompanyType,
                      dropdownColor: const Color(0xFF003A35),
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      iconEnabledColor: Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: _isHindi
                            ? 'कंपनी का प्रकार *'
                            : 'Company Entity Type *',
                        labelStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.apartment_outlined,
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
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _companyTypes.map((String type) {
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
                          setState(() => _selectedCompanyType = val);
                        }
                      },
                    ),
                    SizedBox(height: 22.h),

                    // Section 2: Legal & Tax Verification (KYC)
                    _sectionHeader(
                      _isHindi
                          ? '2. कानूनी और कर सत्यापन (KYC)'
                          : '2. Legal & Tax Verification (KYC)',
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _gstController,
                            label: _isHindi ? 'जीएसटी नंबर *' : 'GST Number *',
                            hint: '07ABCDE1234F1Z5',
                            validatorMsg: _isHindi
                                ? 'जीएसटी नंबर दर्ज करें'
                                : 'Enter GST number',
                            icon: Icons.verified_outlined,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 15,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _panController,
                            label: _isHindi ? 'कंपनी पैन *' : 'Company PAN *',
                            hint: 'ABCDE1234F',
                            validatorMsg: _isHindi
                                ? 'पैन नंबर दर्ज करें'
                                : 'Enter PAN number',
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Section 3: Address & Web Presence
                    _sectionHeader(
                      _isHindi
                          ? '3. पंजीकृत पता और संपर्क'
                          : '3. Corporate Address & Web Presence',
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _addressController,
                      label: _isHindi
                          ? 'पंजीकृत कॉर्पोरेट पता *'
                          : 'Registered Corporate Address *',
                      hint: _isHindi
                          ? 'सड़क का पता, शहर, राज्य और पिनकोड'
                          : 'Enter complete office address, city, state',
                      validatorMsg: _isHindi
                          ? 'कृपया पता दर्ज करें'
                          : 'Enter registered address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    SizedBox(height: 14.h),
                    _buildTextField(
                      controller: _websiteController,
                      label: _isHindi
                          ? 'आधिकारिक वेबसाइट (वैकल्पिक)'
                          : 'Official Website (Optional)',
                      hint: 'https://www.company.com',
                      validatorMsg: '',
                      icon: Icons.language_outlined,
                      isRequired: false,
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: 30.h),

                    // Submit / Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4F4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            side: const BorderSide(
                              color: Color(0xFFC5A038),
                              width: 1,
                            ),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? SizedBox(
                                height: 22.h,
                                width: 22.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    color: const Color(0xFFC5A038),
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _isHindi
                                        ? 'कंपनी विवरण सुरक्षित करें'
                                        : 'Save Company Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFC5A038),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String validatorMsg,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70, fontSize: 13.5.sp),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38, fontSize: 13.sp),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22.sp),
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
          borderSide: const BorderSide(color: Color(0xFFC5A038), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return validatorMsg;
              }
              return null;
            }
          : null,
    );
  }
}
