import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';
import 'package:track_loved/complanyProfile/CompanyPendingVerificationView.dart';
import 'package:track_loved/complanyProfile/companyProfileScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/CreateBusinessOpportunityBodyModel.dart';

class PostBusinessOpportunitiesScreen extends ConsumerStatefulWidget {
  const PostBusinessOpportunitiesScreen({super.key});

  @override
  ConsumerState<PostBusinessOpportunitiesScreen> createState() =>
      PostBusinessOpportunitiesScreenState();
}

class PostBusinessOpportunitiesScreenState
    extends ConsumerState<PostBusinessOpportunitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _opportunityTitleController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _investmentController = TextEditingController();
  final TextEditingController _areaRequiredController = TextEditingController();
  final TextEditingController _returnsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedOpportunityType = 'Start Courier Business / Franchise';
  bool _isHindi = false;
  bool _hasShownDialog = false;
  bool _isLoading = false;
  String? _companyId;

  final List<String> _opportunityTypes = [
    'Start Courier Business / Franchise',
    'Become a Distributor',
    'Super Stockist / C&F Agency',
    'Retail Franchise Store',
    'Channel Partner / Dealership',
    'Other Business Expansion',
  ];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('userdata');
    final savedCompanyName = box.get('companyName', defaultValue: '');
    if (savedCompanyName.toString().trim().isNotEmpty) {
      _companyNameController.text = savedCompanyName.toString().trim();
    }
    final savedPhone = box.get('companyPhone', defaultValue: '');
    if (savedPhone.toString().trim().isNotEmpty) {
      _contactPhoneController.text = savedPhone.toString().trim();
    }
    final savedEmail = box.get('companyEmail', defaultValue: '');
    if (savedEmail.toString().trim().isNotEmpty) {
      _emailController.text = savedEmail.toString().trim();
    }

    // Add listeners to update the live card preview in real time
    _companyNameController.addListener(_refreshPreview);
    _opportunityTitleController.addListener(_refreshPreview);
    _locationController.addListener(_refreshPreview);
    _pincodeController.addListener(_refreshPreview);
    _investmentController.addListener(_refreshPreview);
    _areaRequiredController.addListener(_refreshPreview);
    _returnsController.addListener(_refreshPreview);
    _descriptionController.addListener(_refreshPreview);
    _contactPersonController.addListener(_refreshPreview);
    _contactPhoneController.addListener(_refreshPreview);
    _emailController.addListener(_refreshPreview);
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
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
              ? 'अवसर पोस्ट करने के लिए कृपया पहले अपनी कंपनी प्रोफ़ाइल और KYC विवरण पूरा करें।'
              : 'Please complete your Company Profile and corporate KYC details before posting opportunities.',
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
    _companyNameController.removeListener(_refreshPreview);
    _opportunityTitleController.removeListener(_refreshPreview);
    _locationController.removeListener(_refreshPreview);
    _pincodeController.removeListener(_refreshPreview);
    _investmentController.removeListener(_refreshPreview);
    _areaRequiredController.removeListener(_refreshPreview);
    _returnsController.removeListener(_refreshPreview);
    _descriptionController.removeListener(_refreshPreview);
    _contactPersonController.removeListener(_refreshPreview);
    _contactPhoneController.removeListener(_refreshPreview);
    _emailController.removeListener(_refreshPreview);

    _companyNameController.dispose();
    _opportunityTitleController.dispose();
    _locationController.dispose();
    _pincodeController.dispose();
    _investmentController.dispose();
    _areaRequiredController.dispose();
    _returnsController.dispose();
    _descriptionController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitOpportunity() async {
    if (_formKey.currentState!.validate()) {
      final profileList =
          ref.read(getBussinessProfileProvider).value?.data ?? [];
      final datum = profileList.isNotEmpty ? profileList.first : null;
      final box = Hive.box('userdata');

      final compId =
          _companyId ?? datum?.companyId ?? datum?.id ?? box.get('companyId');

      if (compId == null || compId.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'कंपनी आईडी उपलब्ध नहीं है। कृपया प्रोफ़ाइल जांचें।'
                  : 'Company ID not found. Please verify your company profile.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final companyType =
          datum?.companyType ??
          box.get('companyType', defaultValue: 'Partnership');

      final address = (datum?.registeredCorporateAddress?.isNotEmpty == true)
          ? datum!.registeredCorporateAddress!
          : (box.get('companyAddress', defaultValue: '') as String).isNotEmpty
          ? box.get('companyAddress') as String
          : _locationController.text.trim();

      final state = (datum?.state?.isNotEmpty == true)
          ? datum!.state!
          : (box.get('companyState', defaultValue: '') as String).isNotEmpty
          ? box.get('companyState') as String
          : 'Rajasthan';

      setState(() => _isLoading = true);

      try {
        final body = CreateBusinessOpportunityBodyModel(
          companyId: compId.toString(),
          companyType: companyType.toString(),
          opportunityType: _selectedOpportunityType,
          opportunityHeadline: _opportunityTitleController.text.trim(),
          address: address.toString(),
          city: _locationController.text.trim(),
          state: state.toString(),
          pincode: _pincodeController.text.trim(),
          area: _areaRequiredController.text.trim(),
          requiredInvest: _investmentController.text.trim(),
          expectedReturn: _returnsController.text.trim(),
          opportunityDescription: _descriptionController.text.trim(),
          contactPersonName: _contactPersonController.text.trim(),
          mobileNumber: _contactPhoneController.text.trim(),
          businessEmail: _emailController.text.trim(),
        );

        final authService = ref.read(authServiceProvider);
        final res = await authService.createBusinessOpportunityData(body);

        if (!mounted) return;
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
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
                        ? 'अवसर सफलतापूर्वक पोस्ट हुआ!'
                        : 'Opportunity Posted Successfully!',
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
                      ? 'आपका व्यवसाय विस्तार अवसर सफलतापूर्वक पोस्ट कर दिया गया है।'
                      : 'Your business expansion opportunity listing has been posted successfully and is now active.'),
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
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'अवसर पोस्ट करने में विफल: ${e.toString()}'
                  : 'Failed to post opportunity: ${e.toString()}',
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
          titleEn: 'Post Business Opportunities',
          titleHi: 'व्यापार अवसर पोस्ट करें',
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
        return CompanyProfileRequiredPlaceholder(
          isHindi: _isHindi,
          screenTitleEn: 'Post Business Opportunities',
          screenTitleHi: 'व्यापार अवसर पोस्ट करें',
          scaffoldKey: _scaffoldKey,
          onLanguageChanged: (val) => setState(() => _isHindi = val),
          onCompleteProfile: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            );
          },
        );
      },
      data: (profileModel) {
        final dataList = profileModel.data ?? [];
        final datum = dataList.isNotEmpty ? dataList.first : null;
        final status = (datum?.status ?? profileModel.status ?? '')
            .toLowerCase()
            .trim();

        // 1. Data nahi hai
        if (datum == null || dataList.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompanyProfileRequiredDialog();
          });
          return CompanyProfileRequiredPlaceholder(
            isHindi: _isHindi,
            screenTitleEn: 'Post Business Opportunities',
            screenTitleHi: 'व्यापार अवसर पोस्ट करें',
            scaffoldKey: _scaffoldKey,
            onLanguageChanged: (val) => setState(() => _isHindi = val),
            onCompleteProfile: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
              );
            },
          );
        }

        // 2. Data hai aur status pending hai (or rejected)
        if (status != 'approved') {
          return CompanyPendingVerificationView(
            datum: datum,
            status: status,
            isHindi: _isHindi,
            screenTitleEn: 'Post Business Opportunities',
            screenTitleHi: 'व्यापार अवसर पोस्ट करें',
            scaffoldKey: _scaffoldKey,
            onLanguageChanged: (val) => setState(() => _isHindi = val),
          );
        }

        // 3. Status approved hai -> Form show karo
        _companyId = datum.id;
        if (_companyNameController.text.isEmpty &&
            datum.registeredCompanyName != null) {
          _companyNameController.text = datum.registeredCompanyName!;
        }
        return _buildOpportunityForm(context);
      },
    );
  }

  Widget _buildOpportunityForm(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Post Business Opportunities',
        titleHi: 'व्यापार अवसर पोस्ट करें',
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
                  SizedBox(height: 12.h),

                  // Paid Subscription Banner
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
                        ? 'व्यवसाय विस्तार अवसर प्रकाशित करें'
                        : 'Publish an Expansion Opportunity',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _isHindi
                        ? 'अपने व्यवसाय के विकास के लिए सत्यापित वितरकों, साझेदारों या फ्रेंचाइजी को आमंत्रित करें।'
                        : 'Invite verified distributors, partners, or franchisees for your business growth.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 20.h),

                  // SECTION 1: Company & Opportunity Type
                  _sectionHeader(
                    _isHindi
                        ? '1. कंपनी एवं अवसर का प्रकार'
                        : '1. Company & Opportunity Type',
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    icon: Icons.business,
                    controller: _companyNameController,
                    label: _isHindi
                        ? 'कंपनी / ब्रांड का नाम *'
                        : 'Company / Brand Name *',
                    validatorMsg: _isHindi
                        ? 'कंपनी का नाम दर्ज करें'
                        : 'Please enter company name',
                  ),
                  SizedBox(height: 14.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOpportunityType,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    dropdownColor: const Color(0xFF003A35),
                    iconEnabledColor: Colors.white,
                    decoration: _inputDecoration(
                      _isHindi ? 'अवसर का प्रकार *' : 'Opportunity Type *',
                      icon: Icons.business_center_outlined,
                    ),
                    items: _opportunityTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedOpportunityType = val;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 14.h),
                  _buildTextField(
                    icon: Icons.title,
                    controller: _opportunityTitleController,
                    label: _isHindi
                        ? 'अवसर का शीर्षक / हेडलाइन *'
                        : 'Opportunity Headline / Title *',
                    validatorMsg: _isHindi
                        ? 'शीर्षक दर्ज करें'
                        : 'Please enter opportunity headline',
                  ),
                  SizedBox(height: 20.h),

                  // SECTION 2: Target Location & Requirements
                  _sectionHeader(
                    _isHindi
                        ? '2. लक्षित स्थान एवं पिन कोड'
                        : '2. Target Location & Pin Code',
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          icon: Icons.location_on,
                          controller: _locationController,
                          label: _isHindi
                              ? 'शहर / क्षेत्र *'
                              : 'City / Region *',
                          validatorMsg: _isHindi
                              ? 'शहर दर्ज करें'
                              : 'Enter city / region',
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 1,
                        child: _buildTextField(
                          icon: Icons.pin_drop,
                          controller: _pincodeController,
                          label: _isHindi ? 'पिन कोड *' : 'Pin Code *',
                          validatorMsg: _isHindi
                              ? 'पिन कोड दर्ज करें'
                              : 'Enter pin code',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // SECTION 3: Key Financials & Space Metrics
                  _sectionHeader(
                    _isHindi
                        ? '3. आवश्यक निवेश, स्थान एवं अनुमानित रिटर्न'
                        : '3. Investment, Area & Expected Returns',
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          icon: Icons.account_balance_wallet,
                          controller: _investmentController,
                          label: _isHindi
                              ? 'आवश्यक निवेश *'
                              : 'Required Investment *',
                          validatorMsg: _isHindi
                              ? 'निवेश सीमा दर्ज करें'
                              : 'Enter investment range',
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          icon: Icons.aspect_ratio,
                          controller: _areaRequiredController,
                          label: _isHindi
                              ? 'आवश्यक स्थान (क्षेत्रफल) *'
                              : 'Space / Area Required *',
                          validatorMsg: _isHindi
                              ? 'क्षेत्रफल दर्ज करें'
                              : 'Enter area details',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _buildTextField(
                    icon: Icons.trending_up,
                    controller: _returnsController,
                    label: _isHindi
                        ? 'अनुमानित रिटर्न / लाभ मार्जिन *'
                        : 'Expected Returns / Profit Margin *',
                    validatorMsg: _isHindi
                        ? 'रिटर्न विवरण दर्ज करें'
                        : 'Please specify returns details',
                  ),
                  SizedBox(height: 20.h),

                  // SECTION 4: Description
                  _sectionHeader(
                    _isHindi
                        ? '4. विस्तृत विवरण एवं व्यावसायिक प्रस्ताव'
                        : '4. Detailed Opportunity Description',
                  ),
                  SizedBox(height: 12.h),
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
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      isDense: true,
                      labelText: _isHindi
                          ? 'अवसर का विवरण एवं सहायता विवरण *'
                          : 'Opportunity Description & Support Provided *',
                      labelStyle: TextStyle(
                        color: Colors.white60,
                        fontSize: 14.5.sp,
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
                            ? 'कृपया विवरण दर्ज करें'
                            : 'Please provide description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  // SECTION 5: Contact Information
                  _sectionHeader(
                    _isHindi
                        ? '5. व्यापार भागीदार संपर्क विवरण'
                        : '5. Partner Contact Channel',
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    icon: Icons.person,
                    controller: _contactPersonController,
                    label: _isHindi
                        ? 'संपर्क व्यक्ति का नाम *'
                        : 'Contact Person Name *',
                    validatorMsg: _isHindi
                        ? 'संपर्क व्यक्ति का नाम दर्ज करें'
                        : 'Enter contact person name',
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          icon: Icons.phone,
                          controller: _contactPhoneController,
                          label: _isHindi
                              ? 'मोबाइल / व्हाट्सएप नंबर *'
                              : 'Mobile / WhatsApp Number *',
                          validatorMsg: _isHindi
                              ? 'फ़ोन नंबर दर्ज करें'
                              : 'Enter phone number',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          icon: Icons.email,
                          label: _isHindi
                              ? 'व्यापारिक ईमेल *'
                              : 'Business Email *',
                          validatorMsg: _isHindi
                              ? 'ईमेल दर्ज करें'
                              : 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),
                  // SUBMIT BUTTON
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
                      onPressed: _isLoading ? null : _submitOpportunity,
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
                                  ? 'अवसर सूची प्रकाशित करें'
                                  : 'Publish Opportunity Listing',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 26.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIVE PREVIEW CARD (MATCHES THE USER'S PROVIDED SCREENSHOT)
  // ============================================================
  // ignore: unused_element
  Widget _buildLivePreviewCard() {
    final typeText =
        _selectedOpportunityType ?? 'Start Courier Business / Franchise';
    final locationText = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : 'Faridabad / Delhi NCR';
    final titleText = _opportunityTitleController.text.trim().isNotEmpty
        ? _opportunityTitleController.text.trim()
        : 'Looking for City Distributors for Fast Courier Service';
    final companyText = _companyNameController.text.trim().isNotEmpty
        ? _companyNameController.text.trim()
        : 'SwiftLogistics Express';
    final investmentText = _investmentController.text.trim().isNotEmpty
        ? _investmentController.text.trim()
        : '₹2 Lakhs - ₹5 Lakhs';
    final areaText = _areaRequiredController.text.trim().isNotEmpty
        ? _areaRequiredController.text.trim()
        : '150 - 300 Sq. Ft.';
    final returnsText = _returnsController.text.trim().isNotEmpty
        ? _returnsController.text.trim()
        : '20-25% ROI or Payback...';
    final pincodeText = _pincodeController.text.trim().isNotEmpty
        ? _pincodeController.text.trim()
        : '121001';
    final descriptionText = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : 'Full technology platform, sorting software, uniform kits, and initial branding support provided. Great scope for local last-...';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDCDFE4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type Tag & Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B4F4A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B4F4A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14.sp,
                    color: const Color(0xFF0B4F4A),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    locationText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Title
          Text(
            titleText,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          SizedBox(height: 4.h),

          // Company
          Text(
            companyText,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B4F4A),
            ),
          ),
          SizedBox(height: 12.h),

          // 2x2 Info Badges (Matching Screenshot)
          Row(
            children: [
              Expanded(
                child: _previewInfoBadge(
                  Icons.account_balance_wallet,
                  'Investment',
                  investmentText,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _previewInfoBadge(Icons.aspect_ratio, 'Area', areaText),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _previewInfoBadge(
                  Icons.trending_up,
                  'Returns',
                  returnsText,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _previewInfoBadge(
                  Icons.pin_drop,
                  'Pincode',
                  pincodeText,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Description
          Text(
            descriptionText,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: Colors.black54,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),

          // Contact Business Partner Button
          Container(
            width: double.infinity,
            height: 44.h,
            decoration: BoxDecoration(
              color: const Color(0xFF0B4F4A),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  _isHindi
                      ? 'व्यवसाय भागीदार से संपर्क करें'
                      : 'Contact Business Partner',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewInfoBadge(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0B4F4A), size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5.sp, color: Colors.black54),
                ),
                SizedBox(height: 1.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 14.5.sp),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22.sp),
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
      labelStyle: TextStyle(color: Colors.white60, fontSize: 14.sp),
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
