import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/PostJobOpprtunities.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/BusinessProfileBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/getBusinnesProfileModel.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  final Datum? existingData;

  const CompanyProfileScreen({
    super.key,
    this.isEdit = false,
    this.existingData,
  });

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  bool get _isEditMode =>
      widget.isEdit ||
      widget.existingData != null ||
      (ref.read(getBussinessProfileProvider).value?.data?.isNotEmpty == true) ||
      (Hive.box('userdata').get('isCompanyProfileComplete', defaultValue: false)
          as bool);

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
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

  String? _selectedState;

  // DPDPA & IT Act Intermediary Safe Harbor Mandatory Checkboxes
  bool _agreePurposeLimitation = false;
  bool _agreeSurveillanceProhibition = false;
  bool _agreeDataErasure = false;
  bool _agreeNoEmploymentContract = false;
  static const List<String> _indianStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('userdata');
    final profileData = ref.read(getBussinessProfileProvider).value?.data;
    final datum =
        widget.existingData ??
        (profileData != null && profileData.isNotEmpty
            ? profileData.first
            : null);

    _companyNameController.text =
        datum?.registeredCompanyName ??
        box.get('companyName', defaultValue: '');
    _emailController.text =
        datum?.companyEmail ??
        datum?.ownerContact?.email ??
        box.get(
          'companyEmail',
          defaultValue: box.get('email', defaultValue: ''),
        );
    _phoneController.text =
        datum?.companyPhoneNumber ??
        datum?.ownerContact?.phone ??
        box.get(
          'companyPhone',
          defaultValue: box.get('phone', defaultValue: ''),
        );
    _gstController.text =
        datum?.gstNumber ?? box.get('companyGst', defaultValue: '');
    _panController.text =
        datum?.companyPanNumber ?? box.get('companyPan', defaultValue: '');
    _addressController.text =
        datum?.registeredCorporateAddress ??
        box.get('companyAddress', defaultValue: '');
    _cityController.text =
        datum?.city ?? box.get('companyCity', defaultValue: '');
    _pincodeController.text =
        datum?.pincode ?? box.get('companyPincode', defaultValue: '');
    _websiteController.text =
        datum?.officialWebsite ?? box.get('companyWebsite', defaultValue: '');

    final savedType = datum?.companyType ?? box.get('companyType');
    if (savedType != null && _companyTypes.contains(savedType)) {
      _selectedCompanyType = savedType;
    }
    final savedState = datum?.state ?? box.get('companyState');
    if (savedState != null && _indianStates.contains(savedState)) {
      _selectedState = savedState;
      _stateController.text = savedState;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_agreePurposeLimitation ||
        !_agreeSurveillanceProhibition ||
        !_agreeDataErasure ||
        !_agreeNoEmploymentContract) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'कृपया आगे बढ़ने से पहले सभी 4 अनिवार्य वैधानिक समझौतों को स्वीकार करें।'
                : 'Please accept all 4 mandatory DPDPA statutory terms before proceeding.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? formattedWebsite;
        final rawWebsite = _websiteController.text.trim();
        if (rawWebsite.isNotEmpty) {
          formattedWebsite =
              (rawWebsite.startsWith('http://') ||
                  rawWebsite.startsWith('https://'))
              ? rawWebsite
              : 'https://$rawWebsite';
        }

        final complianceRecord = {
          "compliance_ledger_event": "USER_REGISTRATION_CONSENT_RECORD",
          "schema_version": "TLO-DPDPA-V1.2-2026",
          "timestamp_iso8601": DateTime.now().toUtc().toIso8601String(),
          "session_metadata": {
            "client_platform": "Flutter Mobile",
            "locale": _isHindi ? "hi_IN" : "en_IN",
          },
          "party_identities": {
            "account_role": "business_employer",
            "registered_entity_name": _companyNameController.text.trim(),
            "corporate_identifier":
                _gstController.text.trim().toUpperCase().isNotEmpty
                ? _gstController.text.trim().toUpperCase()
                : _panController.text.trim().toUpperCase(),
            "authorized_signatory_email": _emailController.text.trim(),
          },
          "legal_declarations_logged": {
            "notice_text_version_id": "NOTICE-B2B-2026-V1",
            "unbundled_selections": {
              "purpose_limitation_agreed": _agreePurposeLimitation,
              "location_tracking_blindness_acknowledged":
                  _agreeSurveillanceProhibition,
              "applicant_erasure_mandate_verified": _agreeDataErasure,
              "no_employment_relationship_acknowledged":
                  _agreeNoEmploymentContract,
            },
            "binding_string":
                "I, acting as an authorized corporate agent for this legal entity, give free, informed, specific, unconditional, and unambiguous consent to process our business data as an information intermediary. We acknowledge full restriction from real-time mapping layers and accept data erasure protocols under the DPDP Act, 2023.",
          },
        };

        final body = BusinessProfileBodyModel(
          registeredCompanyName: _companyNameController.text.trim(),
          companyType: _selectedCompanyType,
          companyEmail: _emailController.text.trim(),
          companyPhoneNumber: _phoneController.text.trim(),
          gstNumber: _gstController.text.trim().toUpperCase(),
          companyPanNumber: _panController.text.trim().toUpperCase(),
          registeredCorporateAddress: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedState,
          pincode: _pincodeController.text.trim(),
          officialWebsite: formattedWebsite,
          complianceLedger: complianceRecord,
        );

        final authService = ref.read(authServiceProvider);
        final isEditMode = _isEditMode;
        final response = isEditMode
            ? await authService.updateBusinessProfileData(body)
            : await authService.saveBusinessProfileData(body);

        // Persist locally in Hive
        final box = Hive.box('userdata');
        await box.put('isCompanyProfileComplete', true);
        await box.put('companyName', _companyNameController.text.trim());
        await box.put('companyEmail', _emailController.text.trim());
        await box.put('companyPhone', _phoneController.text.trim());
        await box.put('companyType', _selectedCompanyType);
        await box.put('companyGst', _gstController.text.trim().toUpperCase());
        await box.put('companyPan', _panController.text.trim().toUpperCase());
        await box.put('companyAddress', _addressController.text.trim());
        await box.put('companyCity', _cityController.text.trim());
        await box.put('companyState', _selectedState ?? '');
        await box.put('companyPincode', _pincodeController.text.trim());
        await box.put('companyWebsite', _websiteController.text.trim());

        ref.invalidate(getBussinessProfileProvider);

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF072420),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: const BorderSide(color: Color(0xFFC5A038), width: 1),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFFD4AF37),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? (isEditMode
                              ? 'प्रोफ़ाइल सफलतापूर्वक अपडेट हो गई!'
                              : 'सत्यापन के लिए सबमिट किया गया!')
                        : (isEditMode
                              ? 'Profile Updated Successfully!'
                              : 'Submitted for Verification!'),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              response.message ??
                  (_isHindi
                      ? (isEditMode
                            ? 'आपकी कंपनी का प्रोफ़ाइल विवरण सफलतापूर्वक अपडेट कर दिया गया है।'
                            : 'आपकी कंपनी का प्रोफ़ाइल और KYC विवरण सत्यापन के लिए सफलतापूर्वक सबमिट कर दिया गया है।')
                      : (isEditMode
                            ? 'Your company profile details have been successfully updated.'
                            : 'Your company profile & KYC details have been successfully submitted for verification.')),
              style: TextStyle(
                fontSize: 13.5.sp,
                color: Colors.white70,
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
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PostJobOpportunitiesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    _isHindi ? 'नौकरी पोस्ट पर जाएं' : 'Proceed to Post Job',
                    style: TextStyle(
                      color: const Color(0xFF072420),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
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
      backgroundColor: const Color(0xFF0F3D38),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: _isEditMode ? 'Edit Company Profile' : 'Company Profile & KYC',
        titleHi: _isEditMode
            ? 'कंपनी प्रोफ़ाइल संपादित करें'
            : 'कंपनी प्रोफ़ाइल और केवाईसी',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
        onNotificationPressed: () {},
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 480.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Verification Info Banner Card
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: const Color(
                              0xFFC5A038,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: const Color(0xFFD4AF37),
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
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        _isHindi
                            ? 'कॉर्पोरेट पहचान स्थापित करें'
                            : 'Establish Corporate Identity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _isHindi
                            ? 'यह प्रोफ़ाइल संगठन सत्यापन और व्यावसायिक अनुपालन के लिए आवश्यक है।'
                            : 'This profile is strictly for organization verification and compliance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Section 1: Organization Details
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionHeader(
                          _isHindi
                              ? '1. संगठन की जानकारी'
                              : '1. Organization Details',
                        ),
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
                        dropdownColor: const Color(0xFF072420),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        iconEnabledColor: const Color(0xFFD4AF37),
                        decoration: InputDecoration(
                          labelText: _isHindi
                              ? 'कंपनी का प्रकार *'
                              : 'Company Entity Type *',
                          labelStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 15.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.apartment_outlined,
                            color: Colors.white60,
                            size: 24.sp,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 18.h,
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
                      SizedBox(height: 14.h),

                      // Company Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: _isHindi
                            ? 'कंपनी आधिकारिक ईमेल *'
                            : 'Company Official Email *',
                        hint: 'e.g., info@company.com',
                        validatorMsg: _isHindi
                            ? 'कृपया मान्य ईमेल पता दर्ज करें'
                            : 'Enter valid official email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        customValidator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return _isHindi
                                ? 'कृपया कंपनी ईमेल दर्ज करें'
                                : 'Please enter company email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(val.trim())) {
                            return _isHindi
                                ? 'कृपया एक मान्य ईमेल दर्ज करें'
                                : 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      // Company Admin Contact Number Field
                      _buildTextField(
                        controller: _phoneController,
                        label: _isHindi
                            ? 'कंपनी संपर्क नंबर *'
                            : 'Company Contact Number *',
                        hint: 'e.g., 9876543210',
                        validatorMsg: _isHindi
                            ? 'कृपया मान्य 10 अंकों का संपर्क नंबर दर्ज करें'
                            : 'Enter valid 10-digit contact number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        customValidator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return _isHindi
                                ? 'कृपया कंपनी एडमिन संपर्क नंबर दर्ज करें'
                                : 'Please enter admin contact number';
                          }
                          if (val.trim().length != 10 ||
                              !RegExp(r'^[0-9]+$').hasMatch(val.trim())) {
                            return _isHindi
                                ? 'कृपया 10 अंकों का मान्य फ़ोन नंबर दर्ज करें'
                                : 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.h),

                      // Section 2: Legal & Tax Verification (KYC)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionHeader(
                          _isHindi
                              ? '2. कानूनी और कर सत्यापन (KYC)'
                              : '2. Legal & Tax Verification (KYC)',
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _gstController,
                              label: _isHindi
                                  ? 'जीएसटी नंबर *'
                                  : 'GST Number *',
                              hint: '07ABCDE1234F1Z5',
                              validatorMsg: _isHindi
                                  ? 'जीएसटी नंबर दर्ज करें'
                                  : 'Enter GST number',
                              icon: Icons.verified_outlined,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 15,
                              customValidator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return _isHindi
                                      ? 'जीएसटी नंबर दर्ज करें'
                                      : 'Enter GST number';
                                }
                                final clean = val.trim().toUpperCase();
                                if (!RegExp(
                                  r'^\d{2}[A-Z]{5}\d{4}[A-Z][A-Z\d]Z[A-Z\d]$',
                                ).hasMatch(clean)) {
                                  return _isHindi
                                      ? 'अमान्य GST (उदा. 07ABCDE1234F1Z5, 14वां Z)'
                                      : 'Invalid GST (e.g. 07ABCDE1234F1Z5, 14th Z)';
                                }
                                return null;
                              },
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
                      SizedBox(height: 24.h),

                      // Section 3: Address & Web Presence
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionHeader(
                          _isHindi
                              ? '3. पंजीकृत पता और वेब उपस्थिति'
                              : '3. Corporate Address & Web Presence',
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildTextField(
                        controller: _addressController,
                        label: _isHindi
                            ? 'पंजीकृत कॉर्पोरेट पता (भवन / सड़क / परिसर) *'
                            : 'Registered Corporate Address (Premises / Street) *',
                        hint: _isHindi
                            ? 'उदा. 212, BB Tower, सेक्टर 62'
                            : 'e.g., 212, BB Tower, Sector 62',
                        validatorMsg: _isHindi
                            ? 'कृपया पता दर्ज करें'
                            : 'Enter registered address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      SizedBox(height: 14.h),
                      TextFormField(
                        controller: _stateController,
                        readOnly: true,
                        onTap: _showStateSearchPicker,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: _isHindi ? 'राज्य *' : 'State *',
                          labelStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 15.sp,
                          ),
                          hintText: _isHindi
                              ? 'राज्य चुनें (खोजने के लिए टैप करें)'
                              : 'Select State (Tap to search)',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 13.5.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.map_outlined,
                            color: Colors.white60,
                            size: 24.sp,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search,
                                color: const Color(0xFFD4AF37),
                                size: 20.sp,
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.arrow_drop_down,
                                color: const Color(0xFFD4AF37),
                                size: 24.sp,
                              ),
                              SizedBox(width: 8.w),
                            ],
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 18.h,
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
                            borderSide: const BorderSide(
                              color: Color(0xFFC5A038),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(
                              color: Colors.redAccent,
                              width: 1.5.w,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return _isHindi
                                ? 'कृपया राज्य चुनें'
                                : 'Please select state';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: _isHindi ? 'शहर *' : 'City *',
                              hint: 'e.g., Noida',
                              validatorMsg: _isHindi
                                  ? 'कृपया शहर दर्ज करें'
                                  : 'Enter city',
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _pincodeController,
                              label: _isHindi ? 'पिनकोड *' : 'Pincode *',
                              hint: '201301',
                              validatorMsg: _isHindi
                                  ? 'पिनकोड दर्ज करें'
                                  : 'Enter pincode',
                              icon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              customValidator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return _isHindi
                                      ? 'पिनकोड दर्ज करें'
                                      : 'Enter pincode';
                                }
                                if (!RegExp(
                                  r'^[1-9][0-9]{5}$',
                                ).hasMatch(val.trim())) {
                                  return _isHindi
                                      ? 'मान्य 6 अंकों का पिनकोड'
                                      : 'Valid 6-digit pin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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
                      SizedBox(height: 24.h),

                      // ========================================================================
                      // 1. The Corporate Intermediary Agreement (Intermediary Safe Harbor Guard)
                      // Section 4 & Section 5 DPDP Act, 2023 Compliance
                      // ========================================================================
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF041E1A),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: const Color(0xFFD4AF37),
                                  size: 22.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _isHindi
                                        ? 'नियोक्ता मध्यस्थ सूचना एवं वैधानिक सहमति'
                                        : 'TRACK LOVED ONES: EMPLOYER INTERMEDIARY NOTICE',
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD4AF37),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '[Section 4 & Section 5 DPDP Act, 2023 Compliance]',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _isHindi
                                  ? 'हमारा प्लेटफॉर्म वयस्क नौकरी आवेदकों और व्यापार अवसर चाहने वालों के बीच संबंध सुगम बनाने के लिए केवल एक सूचना मध्यस्थ के रूप में कार्य करता है। नियोक्ता खाते के संचालन के लिए आपको निम्नलिखित कानूनी रूप से बाध्यकारी शर्तों से सहमत होना होगा:'
                                  : 'Our platform acts strictly as an information intermediary to facilitate connections between adult job applicants and business opportunity seekers. To operate an employer account, you must review and agree to the following legally binding terms:',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            const Divider(color: Colors.white24, height: 1),
                            SizedBox(height: 10.h),

                            // Term 1: Recruitment Specific Purpose Limitation
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreePurposeLimitation,
                                  activeColor: const Color(0xFFD4AF37),
                                  checkColor: const Color(0xFF072420),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) => setState(
                                    () =>
                                        _agreePurposeLimitation = val ?? false,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '(Mandatory) RECRUITMENT SPECIFIC PURPOSE LIMITATION',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFE6C567),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _isHindi
                                            ? 'मैं सहमत हूँ कि यह कॉर्पोरेट खाता उम्मीदवार डेटा (नाम, ईमेल, संपर्क नंबर और बायोडाटा) को केवल सक्रिय रोजगार मूल्यांकन के लिए संसाधित करेगा। कोई भी डेटा बाहरी विज्ञापन या मार्केटिंग में साझा या बेचा नहीं जाएगा।'
                                            : 'I agree that this corporate account will process candidate data (names, emails, contact numbers, and resumes) strictly for active employment evaluation. No data obtained here will be reused, sold, or shared with external advertising or marketing data pools.',
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          color: Colors.white70,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // Term 2: Surveillance & Location Tracking Prohibition
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreeSurveillanceProhibition,
                                  activeColor: const Color(0xFFD4AF37),
                                  checkColor: const Color(0xFF072420),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) => setState(
                                    () => _agreeSurveillanceProhibition =
                                        val ?? false,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '(Mandatory) SURVEILLANCE & LOCATION TRACKING PROHIBITION',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFE6C567),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _isHindi
                                            ? 'मैं स्वीकार करता/करती हूँ कि Track Loved Ones ऐप एक उपभोक्ता व्यक्तिगत सुरक्षा उपकरण है। व्यावसायिक प्रोफ़ाइल को रीयल-टाइम पृष्ठभूमि स्थान नेटवर्क में कोई अधिकार या दृश्यता नहीं है। हम लाइव मानचित्र से पूर्णतः अनभिज्ञ (blinded) हैं।'
                                            : 'I acknowledge that Track Loved Ones App is a consumer personal safety utility. Business profiles have zero entitlement, access, or visibility into the real-time background location network. I agree our company will not attempt to intercept candidate coordinates, and we verify we are blinded from the platform live map.',
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          color: Colors.white70,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // Term 3: Data Erasure Compliance Acknowledgement
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreeDataErasure,
                                  activeColor: const Color(0xFFD4AF37),
                                  checkColor: const Color(0xFF072420),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) => setState(
                                    () => _agreeDataErasure = val ?? false,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '(Mandatory) DATA ERASURE COMPLIANCE ACKNOWLEDGEMENT',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFE6C567),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _isHindi
                                            ? 'मैं सत्यापित करता/करती हूँ कि यदि कोई आवेदक DPDP अधिनियम के तहत आवेदन वापस लेता है, तो हमारी कंपनी तुरंत अपने आंतरिक लेजर से उनके बायोडाटा, संपर्क विवरण और संचार इतिहास के सभी स्थानीय स्नैपशॉट को हटा देगी।'
                                            : 'I verify that if an applicant exercises their "Right to be Forgotten" under the DPDP Act and withdraws their job application, our company will immediately delete and strip all local snapshots of their resume, contact details, and communication history from our internal company ledgers.',
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          color: Colors.white70,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // Term 4: No Employment or Contractual Relationship Disclaimer
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreeNoEmploymentContract,
                                  activeColor: const Color(0xFFD4AF37),
                                  checkColor: const Color(0xFF072420),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) => setState(
                                    () => _agreeNoEmploymentContract =
                                        val ?? false,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '(Mandatory) NO EMPLOYMENT OR CONTRACTUAL RELATIONSHIP DISCLAIMER',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFE6C567),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _isHindi
                                            ? 'मैं स्पष्ट रूप से स्वीकार और सहमत करता/करती हूँ कि Track Loved Ones ऐप केवल आवेदकों और नियोक्ताओं के बीच सूचना हस्तांतरण की सुविधा प्रदान करने वाला एक तकनीकी मध्यस्थ है। किसी भी परिस्थिति में पंजीकरण, सदस्यता या अवसर पोस्ट करने से Track Loved Ones ऐप और कंपनी के बीच, या ऐप और किसी नौकरी चाहने वाले के बीच नियोक्ता-कर्मचारी संबंध, एजेंसी, साझेदारी, संयुक्त उद्यम या श्रम-ठेकेदार व्यवस्था नहीं बनती है। कंपनी अपनी भर्ती प्रथाओं और पोस्टिंग के लिए एकमात्र परिचालन दायित्व वहन करती है।'
                                            : 'I explicitly acknowledge and agree that Track Loved Ones App acts solely as a technological intermediary facilitating information transfers between applicants and employers. Under no circumstances does registration, subscription, or posting an opportunity create an employer-employee relationship, agency, partnership, joint venture, or labor-contractor arrangement between Track Loved Ones App and the company, or between Track Loved Ones App and any job seeker. The company retains sole operational liability for its hiring practices and postings.',
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          color: Colors.white70,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Submit for Verification / Activate Workspace Button
                      Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFC5A038,
                              ).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? SizedBox(
                                  height: 24.h,
                                  width: 24.h,
                                  child: const CircularProgressIndicator(
                                    color: Color(0xFF072420),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditMode
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.verified_user_rounded,
                                      color: const Color(0xFF072420),
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        _isHindi
                                            ? (_isEditMode
                                                  ? 'कॉर्पोरेट साख अपडेट करें और सहेजें'
                                                  : 'कॉर्पोरेट साख की पुष्टि करें और कार्यक्षेत्र सक्रिय करें')
                                            : (_isEditMode
                                                  ? 'UPDATE CREDENTIALS & WORKSPACE'
                                                  : 'CONFIRM CORPORATE CREDENTIALS & ACTIVATE WORKSPACE'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFF072420),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5.sp,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStateSearchPicker() async {
    final searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredStates = _indianStates.where((state) {
              return state.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: BoxDecoration(
                color: const Color(0xFF072420),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                border: const Border(
                  top: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                  left: BorderSide(color: Color(0xFFD4AF37), width: 0.5),
                  right: BorderSide(color: Color(0xFFD4AF37), width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isHindi ? 'राज्य चुनें' : 'Select State',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFD4AF37),
                          ),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(color: Colors.white, fontSize: 15.sp),
                      onChanged: (val) {
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F3D38),
                        hintText: _isHindi
                            ? 'राज्य खोजें (उदा. Rajasthan, Maharashtra)...'
                            : 'Search state (e.g. Rajasthan, Maharashtra)...',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 13.5.sp,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFD4AF37),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 16.w,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4AF37),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Expanded(
                    child: filteredStates.isEmpty
                        ? Center(
                            child: Text(
                              _isHindi
                                  ? 'कोई राज्य नहीं मिला'
                                  : 'No state found',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 4.h,
                            ),
                            itemCount: filteredStates.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final stateItem = filteredStates[index];
                              final isSelected = stateItem == _selectedState;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                title: Text(
                                  stateItem,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF00E676)
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 15.sp,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF00E676),
                                        size: 20,
                                      )
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                onTap: () {
                                  Navigator.pop(bottomSheetContext);
                                  setState(() {
                                    _selectedState = stateItem;
                                    _stateController.text = stateItem;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFD4AF37),
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
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 15.sp),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38, fontSize: 13.5.sp),
        prefixIcon: Icon(icon, color: Colors.white60, size: 24.sp),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
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
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5.w),
        ),
      ),
      validator:
          customValidator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return validatorMsg;
                  }
                  return null;
                }
              : null),
    );
  }
}
