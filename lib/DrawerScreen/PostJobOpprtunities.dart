import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';
import 'package:track_loved/complanyProfile/CompanyPendingVerificationView.dart';
import 'package:track_loved/complanyProfile/companyProfileScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/CreateJobPostBodyModel.dart';

class PostJobOpportunitiesScreen extends ConsumerStatefulWidget {
  const PostJobOpportunitiesScreen({super.key});

  @override
  ConsumerState<PostJobOpportunitiesScreen> createState() =>
      _PostJobOpportunitiesScreenState();
}

class _PostJobOpportunitiesScreenState
    extends ConsumerState<PostJobOpportunitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _employerController = TextEditingController();
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
  bool _hasShownDialog = false;
  bool _isLoading = false;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('userdata');
    final savedCompanyName = box.get('companyName', defaultValue: '');
    if (savedCompanyName.toString().trim().isNotEmpty) {
      _employerController.text = savedCompanyName.toString().trim();
    }
  }

  Future<void> _showCompanyProfileRequiredDialog() async {
    if (_hasShownDialog || !mounted) return;
    _hasShownDialog = true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF072420),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFC5A038), width: 1),
        ),
        title: Row(
          children: [
            Icon(
              Icons.business_rounded,
              color: const Color(0xFFD4AF37),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi
                    ? 'कंपनी प्रोफ़ाइल अधूरी है'
                    : 'Company Profile Required',
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
          _isHindi
              ? 'नौकरी पोस्ट करने के लिए कृपया पहले अपनी कंपनी प्रोफ़ाइल और KYC विवरण पूरा करें।'
              : 'Please complete your Company Profile and corporate KYC details before posting job opportunities.',
          style: TextStyle(
            fontSize: 13.5.sp,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop(false);
            },
            child: Text(
              _isHindi ? 'रद्द करें' : 'Cancel',
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
                Navigator.of(dialogCtx).pop(true);
              },
              child: Text(
                _isHindi
                    ? 'कंपनी प्रोफ़ाइल पूरी करें'
                    : 'Complete Company Profile',
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

    if (!mounted) return;

    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _employerController.dispose();
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

  void _submitJob() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPincodes.isEmpty &&
          _pincodeInputController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'कृपया कम से कम एक लक्ष्य पिन कोड जोड़ें।'
                  : 'Please select at least one target pin code.',
            ),
          ),
        );
        return;
      }

      final profileList =
          ref.read(getBussinessProfileProvider).value?.data ?? [];
      final firstDatum = profileList.isNotEmpty ? profileList.first : null;
      final compId =
          _companyId ??
          firstDatum?.companyId ??
          firstDatum?.id ??
          Hive.box('userdata').get('companyId');

      if (compId == null || compId.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'कंपनी आईडी उपलब्ध नहीं है। कृपया पहले अपनी कंपनी प्रोफ़ाइल पूरी करें।'
                  : 'Company ID not found. Please complete your company profile first.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final ctcNum =
            num.tryParse(
              _annualCtcController.text.replaceAll(',', '').trim(),
            ) ??
            0;

        String mapEmploymentType(String? type) {
          final lower = (type ?? '').toLowerCase();
          if (lower.contains('part')) {
            return 'part-time';
          }
          if (lower.contains('contract') || lower.contains('project')) {
            return 'contract';
          }
          if (lower.contains('remote') || lower.contains('wfh')) {
            return 'remote';
          }
          if (lower.contains('intern')) {
            return 'internship';
          }
          return 'full-time';
        }

        String mapHierarchyLevel(String? level) {
          final lower = (level ?? '').toLowerCase();
          if (lower.contains('frontline')) return 'frontline';
          if (lower.contains('senior')) return 'senior';
          return 'mid-level';
        }

        final targetPin = _selectedPincodes.isNotEmpty
            ? _selectedPincodes.first
            : _pincodeInputController.text.trim();

        final List<String> perksList = _perksController.text.trim().isNotEmpty
            ? _perksController.text
                  .split(RegExp(r'[,]+'))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : [];

        final List<String> reimbursementsList =
            _reimbursementsController.text.trim().isNotEmpty
            ? _reimbursementsController.text
                  .split(RegExp(r'[,]+'))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : [];

        final List<String> reqs = [];
        if (_descriptionController.text.trim().isNotEmpty) {
          final lines = _descriptionController.text
              .split(RegExp(r'[\r\n,]+'))
              .map((e) => e.replaceAll(RegExp(r'^[-•*0-9.]+\s*'), '').trim())
              .where((e) => e.isNotEmpty)
              .toList();
          reqs.addAll(lines);
        }
        if (reqs.isEmpty) {
          reqs.add('Standard Qualifications');
        }

        String contactEmail = _contactController.text.trim();
        if (!contactEmail.contains('@')) {
          final box = Hive.box('userdata');
          final fallbackEmail =
              firstDatum?.companyEmail ??
              firstDatum?.ownerContact?.email ??
              box.get('companyEmail') ??
              box.get('email');
          if (fallbackEmail != null && fallbackEmail.toString().isNotEmpty) {
            contactEmail = fallbackEmail.toString().trim();
          }
        }

        final stateVal =
            firstDatum?.state ??
            (Hive.box('userdata').get('companyState', defaultValue: '')
                as String);

        final body = CreateJobPostBodyModel(
          companyId: compId.toString(),
          jobTitle: _jobTitleController.text.trim(),
          employmentType: mapEmploymentType(_selectedJobType),
          hierarchyLevel: mapHierarchyLevel(_selectedLevel),
          city: _locationController.text.trim(),
          state: stateVal.isNotEmpty ? stateVal : "Rajasthan",
          pincode: targetPin,
          annualCtcPackage: ctcNum,
          reimbursements: reimbursementsList,
          perksAndBenefits: perksList,
          jobDescription: _descriptionController.text.trim(),
          requirements: reqs,
          applicationContactEmail: contactEmail,
        );

        log('Creating job post with body: ${body.toJson()}');
        final authService = ref.read(authServiceProvider);
        final res = await authService.createJobPostData(body);

        if (!mounted) return;
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
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
                        ? 'नौकरी सफलतापूर्वक पोस्ट हुई!'
                        : 'Job Posted Successfully!',
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
              res.message ??
                  (_isHindi
                      ? 'आपका नौकरी का अवसर सफलतापूर्वक पोस्ट कर दिया गया है।'
                      : 'Your job listing targeting ${_selectedPincodes.isNotEmpty ? _selectedPincodes.length : 1} pin code(s) is now active.'),
              style: TextStyle(
                fontSize: 13.5.sp,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: Text(
                  _isHindi ? 'पूर्ण' : 'Done',
                  style: TextStyle(
                    color: const Color(0xFFE6C567),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        log('Error creating job post: $e');
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'नौकरी पोस्ट करने में त्रुटि: ${e.toString().replaceAll('Exception: ', '')}'
                  : 'Failed to post job: ${e.toString().replaceAll('Exception: ', '')}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(getBussinessProfileProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0F3D38),
        appBar: AppBarScreen(
          titleEn: 'Post Job Opportunities',
          titleHi: 'नौकरी के अवसर पोस्ट करें',
          isHindi: _isHindi,
          notificationCount: 2,
          onLanguageChanged: (val) => setState(() => _isHindi = val),
          onNotificationPressed: () {},
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFC5A038)),
        ),
      ),
      error: (err, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCompanyProfileRequiredDialog();
        });
        return Scaffold(
          backgroundColor: const Color(0xFF0F3D38),
          appBar: AppBarScreen(
            titleEn: 'Post Job Opportunities',
            titleHi: 'नौकरी के अवसर पोस्ट करें',
            isHindi: _isHindi,
            notificationCount: 2,
            onLanguageChanged: (val) => setState(() => _isHindi = val),
            onNotificationPressed: () {},
          ),
          body: const SizedBox.shrink(),
        );
      },
      data: (profileData) {
        final dataList = profileData.data ?? [];
        if (dataList.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompanyProfileRequiredDialog();
          });
          return Scaffold(
            backgroundColor: const Color(0xFF0F3D38),
            appBar: AppBarScreen(
              titleEn: 'Post Job Opportunities',
              titleHi: 'नौकरी के अवसर पोस्ट करें',
              isHindi: _isHindi,
              notificationCount: 2,
              onLanguageChanged: (val) => setState(() => _isHindi = val),
              onNotificationPressed: () {},
            ),
            body: const SizedBox.shrink(),
          );
        }

        final datum = dataList.first;
        final status = (datum.status ?? 'pending').toLowerCase();

        // 1. Data hai aur status rejected hai
        if (status == 'rejected') {
          return CompanyPendingVerificationView(
            datum: datum,
            status: status,
            isHindi: _isHindi,
            screenTitleEn: 'Post Job Opportunities',
            screenTitleHi: 'नौकरी के अवसर पोस्ट करें',
            scaffoldKey: _scaffoldKey,
            onLanguageChanged: (val) => setState(() => _isHindi = val),
          );
        }

        // 2. Data hai aur status pending hai (or rejected)
        if (status != 'approved') {
          return CompanyPendingVerificationView(
            datum: datum,
            status: status,
            isHindi: _isHindi,
            screenTitleEn: 'Post Job Opportunities',
            screenTitleHi: 'नौकरी के अवसर पोस्ट करें',
            scaffoldKey: _scaffoldKey,
            onLanguageChanged: (val) => setState(() => _isHindi = val),
          );
        }

        // 3. Status approved hai -> Form show karo
        _companyId = datum.companyId ?? datum.id;
        if (_companyId != null && _companyId!.isNotEmpty) {
          Hive.box('userdata').put('companyId', _companyId);
        }
        if (_employerController.text.isEmpty &&
            datum.registeredCompanyName != null) {
          _employerController.text = datum.registeredCompanyName!;
        }
        return _buildJobForm(context);
      },
    );
  }

  Widget _buildJobForm(BuildContext context) {
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
                    _isHindi ? 'नौकरी सूची बनाएं' : 'Create Job Listing',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _isHindi
                        ? 'मुआवजा, स्तर और लक्षित क्षेत्र निर्धारित करें।'
                        : 'Define compensation, levels, and specific target areas.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader(
                    _isHindi
                        ? '1. पद एवं वरिष्ठता स्तर'
                        : '1. Role & Seniority Level',
                  ),
                  SizedBox(height: 10.h),

                  // Job Title
                  _buildTextField(
                    controller: _jobTitleController,
                    label: _isHindi
                        ? 'पद का नाम / पदनाम *'
                        : 'Job Title / Designation *',
                    validatorMsg: _isHindi
                        ? 'पद का नाम दर्ज करें'
                        : 'Enter job title',
                    icon: Icons.work_outline,
                  ),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedJobType,
                    decoration: _inputDecoration(
                      _isHindi ? 'रोजगार का प्रकार *' : 'Employment Type *',
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
                      _isHindi ? 'पदानुक्रम स्तर *' : 'Hierarchy Level *',
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
                  _sectionHeader(
                    _isHindi
                        ? '2. स्थान एवं लक्षित पिन कोड'
                        : '2. Location & Target Pin Codes',
                  ),
                  SizedBox(height: 10.h),
                  // Location
                  _buildTextField(
                    controller: _locationController,
                    label: _isHindi
                        ? 'मूल शहर / स्थान *'
                        : 'Base City / Location *',
                    validatorMsg: _isHindi
                        ? 'स्थान दर्ज करें'
                        : 'Enter location',
                    icon: Icons.location_on_outlined,
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _pincodeInputController,
                          label: _isHindi
                              ? 'लक्षित पिन कोड जोड़ें'
                              : 'Add Target Pin Code',
                          validatorMsg: _isHindi
                              ? 'पिन कोड दर्ज करें'
                              : 'Enter pin code',
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
                            _isHindi ? 'पिन जोड़ें' : 'Add Pin',
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
                  _sectionHeader(
                    _isHindi
                        ? '3. वार्षिक CTC, भत्ते एवं प्रतिपूर्ति'
                        : '3. Annual CTC, Perks & Reimbursements',
                  ),
                  SizedBox(height: 10.h),
                  // Annual CTC
                  _buildTextField(
                    controller: _annualCtcController,
                    label: _isHindi
                        ? 'वार्षिक CTC पैकेज *'
                        : 'Annual CTC Package *',
                    validatorMsg: _isHindi
                        ? 'CTC विवरण दर्ज करें'
                        : 'Enter CTC details',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _perksController,
                          label: _isHindi
                              ? 'भत्ते एवं लाभ'
                              : 'Perks & Benefits',
                          validatorMsg: _isHindi
                              ? 'भत्ते दर्ज करें'
                              : 'Enter perks',
                          icon: Icons.card_giftcard_outlined,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _reimbursementsController,
                          label: _isHindi ? 'प्रतिपूर्ति' : 'Reimbursements',
                          validatorMsg: _isHindi
                              ? 'प्रतिपूर्ति दर्ज करें'
                              : 'Enter reimbursements',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader(
                    _isHindi
                        ? '4. जिम्मेदारियां एवं आवेदन विवरण'
                        : '4. Responsibilities & Application Details',
                  ),
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
                      labelText: _isHindi
                          ? 'नौकरी का विवरण एवं आवश्यकताएं *'
                          : 'Job Description & Requirements *',
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _isHindi
                            ? 'विवरण दर्ज करें'
                            : 'Enter job description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  // Contact
                  _buildTextField(
                    controller: _contactController,
                    label: _isHindi
                        ? 'आवेदन संपर्क (ईमेल / फोन) *'
                        : 'Application Contact (Email / Phone) *',
                    validatorMsg: _isHindi
                        ? 'संपर्क जानकारी दर्ज करें'
                        : 'Enter application contact',
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
                      onPressed: _isLoading ? null : _submitJob,
                      child: _isLoading
                          ? SizedBox(
                              height: 22.h,
                              width: 22.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _isHindi
                                  ? 'नौकरी सूची प्रकाशित करें'
                                  : 'Publish Job Listing',
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
