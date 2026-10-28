import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/ManageMyPostingsScreen.dart';
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
  final TextEditingController _departmentCategoryController =
      TextEditingController();
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _officeAddressController =
      TextEditingController();
  final TextEditingController _pincodeInputController = TextEditingController();
  final TextEditingController _annualCtcController = TextEditingController();
  final TextEditingController _perksController = TextEditingController();
  final TextEditingController _reimbursementsController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _desiredProfileController =
      TextEditingController();
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

  // DPDPA & IT Act Sec 79 Mandatory Compliance Assurances
  bool _agreeAuthenticListing = false;
  bool _agreeNoEmploymentRelationship = false;
  bool _agreeAuthorizedRepresentative = false;

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
    _departmentCategoryController.dispose();
    _employerController.dispose();
    _locationController.dispose();
    _officeAddressController.dispose();
    _pincodeInputController.dispose();
    _annualCtcController.dispose();
    _perksController.dispose();
    _reimbursementsController.dispose();
    _descriptionController.dispose();
    _desiredProfileController.dispose();
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

        if (_desiredProfileController.text.trim().isNotEmpty) {
          reqs.add(_desiredProfileController.text.trim());
        }

        final body = CreateJobPostBodyModel(
          companyId: compId.toString(),
          jobTitle: _jobTitleController.text.trim(),
          departmentCategory: _departmentCategoryController.text.trim(),
          employmentType: mapEmploymentType(_selectedJobType),
          hierarchyLevel: mapHierarchyLevel(_selectedLevel),
          city: _locationController.text.trim(),
          officeAddress: _officeAddressController.text.trim(),
          state: stateVal.isNotEmpty ? stateVal : "Rajasthan",
          pincode: targetPin,
          annualCtcPackage: ctcNum,
          reimbursements: reimbursementsList,
          perksAndBenefits: perksList,
          jobDescription: _descriptionController.text.trim(),
          desiredCandidateProfile: _desiredProfileController.text.trim(),
          requirements: reqs,
          applicationContactEmail: contactEmail,
          authenticListingCertified: _agreeAuthenticListing,
          noEmploymentRelationshipDeclared: _agreeNoEmploymentRelationship,
          authorizedRepresentativeCertified: _agreeAuthorizedRepresentative,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) =>
                          ManageMyPostingsScreen(initialHindi: _isHindi),
                    ),
                  );
                },
                child: Text(
                  _isHindi ? 'मेरी पोस्ट देखें' : 'View In My Postings',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageMyPostingsScreen(
                                initialHindi: _isHindi,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3D38),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(
                                0xFFE6C567,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                color: const Color(0xFFE6C567),
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _isHindi
                                    ? 'मेरी पोस्ट प्रबंधित करें'
                                    : 'Manage My Postings',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE6C567),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
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
                    _isHindi
                        ? 'नया व्यापार / नौकरी अवसर बनाएं'
                        : 'CREATE NEW BUSINESS OPPORTUNITY POSTING',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _isHindi
                        ? '[ * से चिह्नित फ़ील्ड प्लेटफ़ॉर्म सेफ हार्बर बनाए रखने के लिए अनिवार्य हैं ]'
                        : '[ Fields marked with * are mandatory to maintain Platform Safe Harbor ]',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _sectionHeader(
                    _isHindi
                        ? '📋 अवसर विवरण (OPPORTUNITY DETAILS)'
                        : '📋 OPPORTUNITY DETAILS',
                  ),
                  SizedBox(height: 10.h),

                  // Job Title
                  _buildTextField(
                    controller: _jobTitleController,
                    label: _isHindi
                        ? '* नौकरी / अवसर का शीर्षक *'
                        : '* Job / Opportunity Title *',
                    hint: 'e.g., Regional Sales Executive',
                    validatorMsg: _isHindi
                        ? 'पद का शीर्षक दर्ज करें'
                        : 'Enter opportunity title',
                    icon: Icons.work_outline,
                  ),
                  SizedBox(height: 16.h),

                  // Department / Category
                  _buildTextField(
                    controller: _departmentCategoryController,
                    label: _isHindi
                        ? '* विभाग / श्रेणी *'
                        : '* Department / Category *',
                    hint: 'e.g., Customer Success, Sales, Operations',
                    validatorMsg: _isHindi
                        ? 'विभाग / श्रेणी दर्ज करें'
                        : 'Enter department / category',
                    icon: Icons.category_outlined,
                  ),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedJobType,
                    decoration: _inputDecoration(
                      _isHindi ? '* रोजगार का प्रकार *' : '* Employment Type *',
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
                  // Screen 1: Static Location Constraint Notice (Safe Harbor)
                  Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          color: const Color(0xFFD4AF37),
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION SPECIFICATION (STATIC TEXT ONLY)',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                _isHindi
                                    ? 'चेतावनी: आपको इस पोस्ट में लाइव ट्रैकिंग लिंक, निरंतर जियोफेंस या रीयल-टाइम जीपीएस आवश्यकताओं को जोड़ने की सख्त मनाही है।'
                                    : '⚠️ Compliance Notice: You are strictly prohibited from embedding live tracking links, continuous geofences, or real-time GPS requirements into this post.',
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
                  ),
                  // Location City
                  _buildTextField(
                    controller: _locationController,
                    label: _isHindi
                        ? '* कार्य स्थल का शहर (City) *'
                        : '* Work Location City *',
                    hint: 'e.g., New Delhi, Delhi',
                    validatorMsg: _isHindi
                        ? 'शहर दर्ज करें'
                        : 'Enter location city',
                    icon: Icons.location_on_outlined,
                  ),
                  SizedBox(height: 16.h),

                  // Office Address (Optional)
                  _buildTextField(
                    controller: _officeAddressController,
                    label: _isHindi
                        ? 'कार्यालय का पता (वैकल्पिक)'
                        : 'Office Address (Optional)',
                    hint: 'e.g., 12, Barakhamba Road, Connaught Place',
                    isRequired: false,
                    validatorMsg: '',
                    icon: Icons.apartment_outlined,
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
                        ? '📝 विवरण एवं आवश्यकताएं (DESCRIPTION & REQUIREMENTS)'
                        : '📝 DESCRIPTION & REQUIREMENTS',
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textAlign: TextAlign.justify,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      isDense: true,
                      labelText: _isHindi
                          ? '* अवसर का विवरण (Opportunity Description) *'
                          : '* Opportunity Description *',
                      hintText: _isHindi
                          ? 'मुख्य जिम्मेदारियां और दैनिक कार्य यहां दर्ज करें'
                          : 'Provide core responsibilities and daily tasks here',
                      hintStyle: TextStyle(
                        color: Colors.white30,
                        fontSize: 13.sp,
                      ),
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
                            : 'Enter opportunity description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Desired Candidate Profile
                  _buildTextField(
                    controller: _desiredProfileController,
                    label: _isHindi
                        ? 'इच्छित उम्मीदवार प्रोफ़ाइल (Desired Profile)'
                        : 'Desired Candidate Profile',
                    hint: _isHindi
                        ? 'आवश्यक कौशल, योग्यता या अनुभव दर्ज करें'
                        : 'Provide required skillsets, qualifications, or experience',
                    isRequired: false,
                    validatorMsg: '',
                    maxLines: 2,
                    icon: Icons.psychology_outlined,
                  ),
                  SizedBox(height: 16.h),

                  // Contact
                  _buildTextField(
                    controller: _contactController,
                    label: _isHindi
                        ? 'आवेदन संपर्क (ईमेल / फोन) *'
                        : 'Application Contact (Email / Phone) *',
                    hint: 'e.g., hr@company.com or +91 9876543210',
                    validatorMsg: _isHindi
                        ? 'संपर्क जानकारी दर्ज करें'
                        : 'Enter application contact',
                    icon: Icons.contact_phone_outlined,
                  ),
                  SizedBox(height: 20.h),
                  // ========================================================================
                  // MANDATORY JOB POSTING COMPLIANCE DISCLOSURE
                  // [IT Act Sec 79 & DPDP Act Sec 6 Purpose Limitation]
                  // ========================================================================
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF041E1A),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
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
                              color: const Color(0xFFD4AF37),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _isHindi
                                    ? 'अनिवार्य नौकरी पोस्टिंग अनुपालन प्रकटीकरण'
                                    : 'MANDATORY JOB POSTING COMPLIANCE DISCLOSURE',
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
                          '[IT Act Sec 79 & DPDP Act Sec 6 Purpose Limitation]',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _isHindi
                              ? 'इस अवसर को प्रकाशित करके, कंपनी स्पष्ट रूप से निम्नलिखित का प्रतिनिधित्व करती है:'
                              : 'By publishing this opportunity, the Company explicitly represents, warrants, and covenants the following to Track Loved Ones App:',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '1. Authentic Listing: Valid, existing opening within legal organization. Data gathering/profiling strictly prohibited.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white60,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '2. Fee Prohibition: No fee, security deposit, processing charge, or laptop/device payment will ever be demanded.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white60,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '3. Complete Location Blindness: Zero access to real-time geographic tracking assets of applicants. Location is static text only.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white60,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        const Divider(color: Colors.white24, height: 1),
                        SizedBox(height: 10.h),
                        // Checkbox 1
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreeAuthenticListing,
                              activeColor: const Color(0xFFD4AF37),
                              checkColor: const Color(0xFF072420),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) {
                                setState(
                                  () => _agreeAuthenticListing = val ?? false,
                                );
                              },
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                _isHindi
                                    ? '* मैं सत्यापित करता/करती हूँ कि यह अवसर एक वैध, सक्रिय अवसर है और आवेदक से किसी भी भुगतान या वित्तीय जमा की मांग नहीं करता है।'
                                    : '* I verify that this opportunity represents a legitimate, active opening and does not demand any payment, registration fees, or financial token deposits from the applicant.',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Checkbox 2
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreeNoEmploymentRelationship,
                              activeColor: const Color(0xFFD4AF37),
                              checkColor: const Color(0xFF072420),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) {
                                setState(
                                  () => _agreeNoEmploymentRelationship =
                                      val ?? false,
                                );
                              },
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                _isHindi
                                    ? '* मैं स्पष्ट रूप से घोषित करता/करती हूँ कि यह पोस्टिंग Track Loved Ones ऐप और आवेदक के बीच, या ऐप और कंपनी के बीच नियोक्ता-कर्मचारी संबंध स्थापित नहीं करती है। Track Loved Ones ऐप केवल एक सूचना मध्यस्थ है।'
                                    : '* I explicitly declare that this posting DOES NOT constitute or imply an employer-employee, master-servant, or contractual labor relationship between Track Loved Ones App and the applicant, nor between Track Loved Ones App and the posting entity. Track Loved Ones App is solely a technology intermediary.',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Checkbox 3
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreeAuthorizedRepresentative,
                              activeColor: const Color(0xFFD4AF37),
                              checkColor: const Color(0xFF072420),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) {
                                setState(
                                  () => _agreeAuthorizedRepresentative =
                                      val ?? false,
                                );
                              },
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                _isHindi
                                    ? '* (आवश्यक) मैं प्रमाणित करता/करती हूँ कि मैं एक अधिकृत कॉर्पोरेट प्रतिनिधि हूँ और इस पोस्ट की वैधता के लिए एकमात्र कानूनी दायित्व स्वीकार करता/करती हूँ।'
                                    : '* (Required) I certify that I am an authorized corporate representative and accept sole legal and penal liability for the validity of this post.',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_agreeAuthenticListing &&
                                _agreeNoEmploymentRelationship &&
                                _agreeAuthorizedRepresentative)
                            ? const Color(0xFF0B4F4A)
                            : Colors.white24,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                      ),
                      // Gate publish until mandatory legal checkboxes are satisfied
                      onPressed:
                          (_isLoading ||
                              !_agreeAuthenticListing ||
                              !_agreeNoEmploymentRelationship ||
                              !_agreeAuthorizedRepresentative)
                          ? null
                          : _submitJob,
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
                                  ? '🚀 अवसर को नेटवर्क पर प्रकाशित करें'
                                  : '🚀 PUBLISH OPPORTUNITY TO THE NETWORK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5.sp,
                                letterSpacing: 0.5,
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
    String? hint,
    bool isRequired = true,
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
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white30, fontSize: 13.sp),
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
        if (isRequired && (value == null || value.trim().isEmpty)) {
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
