import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class ChildToAdultUpgradeScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const ChildToAdultUpgradeScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<ChildToAdultUpgradeScreen> createState() =>
      _ChildToAdultUpgradeScreenState();
}

class _ChildToAdultUpgradeScreenState
    extends ConsumerState<ChildToAdultUpgradeScreen> {
  late bool _isHindi;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();

  DateTime? _selectedDob;
  int _calculatedAge = 0;
  String _selectedIdType = 'Aadhaar Card';
  bool _agreedToDeclaration = false;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  bool _frontIdUploaded = false;
  bool _backIdUploaded = false;
  bool _isSubmitting = false;

  final List<String> _idTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Voter ID Card',
    'Passport',
    'Driving License',
  ];

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadUserStatus();
  }

  void _loadUserStatus() {
    try {
      final box = Hive.box('userdata');
      _nameController.text = box.get('name', defaultValue: '') as String;
      final savedDob = box.get('dob', defaultValue: '') as String;
      if (savedDob.isNotEmpty) {
        _dobController.text = savedDob;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    // Default 18 years ago
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final initialDate = _selectedDob ?? eighteenYearsAgo;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Color(0xFF072420),
              surface: Color(0xFF072420),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF072420),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';

        // Calculate age
        int age = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _calculatedAge = age;
      });
    }
  }

  void _submitUpgrade() async {
    if (!_formKey.currentState!.validate()) return;

    if (_calculatedAge < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'बालिग प्रमाणीकरण के लिए आपकी आयु 18 वर्ष या उससे अधिक होनी चाहिए।'
                : 'You must be at least 18 years of age to upgrade to an adult account.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }

    if (!_agreedToDeclaration) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'कृपया आगे बढ़ने से पहले स्व-घोषणा (Self-declaration) स्वीकार करें।'
                : 'Please check the self-declaration box to confirm your legal consent.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final box = Hive.box('userdata');
      await box.put('account_type', 'adult_upgrade_pending');
      await box.put('adult_upgrade_submitted', true);
      await box.put('adult_id_type', _selectedIdType);
      await box.put('dob', _dobController.text);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSubmitting = false);

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
            const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFFD4AF37),
              size: 26,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _isHindi
                    ? 'अनुरोध सफलतापूर्वक सबमिट!'
                    : 'Upgrade Request Submitted!',
                style: GoogleFonts.outfit(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isHindi
              ? 'बालिग खाता (18+) प्रमाणीकरण के लिए आपके दस्तावेज़ सफलतापूर्वक सबमिट कर दिए गए हैं। सत्यापन पूरा होने पर आपका खाता स्वतंत्र वयस्क खाते में बदल जाएगा।'
              : 'Your documents and date of birth have been securely submitted for adult (18+) verification. Once verified, parental controls will be removed and your account will become fully self-governed.',
          style: GoogleFonts.outfit(
            fontSize: 13.5.sp,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: Text(
              _isHindi ? 'पूर्ण' : 'Done',
              style: GoogleFonts.outfit(
                color: const Color(0xFF072420),
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
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D38),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F3D38),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isHindi ? 'बालिग खाता प्रमाणीकरण (18+)' : 'Upgrade to Adult Account',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 17.5.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header Banner
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          brightGold.withValues(alpha: 0.15),
                          brandGold.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: brandGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.child_care_rounded,
                                color: Colors.orangeAccent,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isHindi
                                        ? 'वर्तमान स्थिति: नाबालिग / चाइल्ड खाता'
                                        : 'Current Status: Minor Account',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _isHindi
                                        ? 'माता-पिता / अभिभावक की निगरानी में'
                                        : 'Under Parental / Guardian Supervision',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.orangeAccent,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '< 18 Yrs',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        const Divider(color: Colors.white12, height: 1),
                        SizedBox(height: 10.h),
                        Text(
                          _isHindi
                              ? 'जब कोई उपयोगकर्ता 18 वर्ष की आयु पूरी कर लेता है, तो वह स्वतंत्र वयस्क खाते में अपग्रेड करके अपने खाते का पूर्ण नियंत्रण और अवसर पोस्टिंग अधिकार प्राप्त कर सकता है।'
                              : 'Upon turning 18, users can transition to a self-managed adult account with independent privacy rights under DPDP compliance rules.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // Section Title
                  Text(
                    _isHindi ? 'आयु एवं पहचान सत्यापन' : 'Age & Identity Verification',
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: brightGold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Legal Full Name
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    decoration: _inputDecoration(
                      label: _isHindi ? 'कानूनी पूरा नाम *' : 'Legal Full Name *',
                      hint: 'As on Govt ID proof',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया पूरा नाम दर्ज करें'
                            : 'Please enter legal full name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Date of Birth Field
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dobController,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15.sp,
                        ),
                        decoration: _inputDecoration(
                          label: _isHindi
                              ? 'जन्म तिथि (DOB) *'
                              : 'Date of Birth (DOB) *',
                          hint: 'DD/MM/YYYY',
                          icon: Icons.cake_outlined,
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            color: brightGold,
                            size: 20.sp,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return _isHindi
                                ? 'कृपया जन्म तिथि चुनें'
                                : 'Please select date of birth';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  if (_calculatedAge > 0) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          _calculatedAge >= 18
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _calculatedAge >= 18
                              ? const Color(0xFF00E676)
                              : Colors.redAccent,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _isHindi
                              ? 'गणना की गई आयु: $_calculatedAge वर्ष (${_calculatedAge >= 18 ? 'बालिग - पात्र' : 'नाबालिग - अपात्र'})'
                              : 'Calculated Age: $_calculatedAge Years (${_calculatedAge >= 18 ? 'Eligible Adult' : 'Minor - Not yet 18'})',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: _calculatedAge >= 18
                                ? const Color(0xFF00E676)
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 14.h),

                  // Govt ID Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIdType,
                    dropdownColor: const Color(0xFF072420),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    iconEnabledColor: brightGold,
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'पहचान प्रमाण पत्र प्रकार *'
                          : 'Government ID Type *',
                      hint: 'Select ID type',
                      icon: Icons.badge_outlined,
                    ),
                    items: _idTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, style: GoogleFonts.outfit(fontSize: 14.sp)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedIdType = val);
                    },
                  ),
                  SizedBox(height: 14.h),

                  // ID Number
                  TextFormField(
                    controller: _idNumberController,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'दस्तावेज़ संख्या (ID Number) *'
                          : 'Document ID Number *',
                      hint: 'e.g., ABCD1234E or XXXX-XXXX-1234',
                      icon: Icons.credit_card_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया आईडी नंबर दर्ज करें'
                            : 'Please enter ID number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 18.h),

                  // Document Upload Cards
                  Text(
                    _isHindi
                        ? 'आईडी दस्तावेज़ अपलोड करें (फ्रंट और बैक)'
                        : 'Upload ID Proof (Front & Back)',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUploadCard(
                          title: _isHindi ? 'फ्रंट साइड' : 'Front Side',
                          isUploaded: _frontIdUploaded,
                          isLoading: _isUploadingFront,
                          onTap: () async {
                            setState(() => _isUploadingFront = true);
                            await Future.delayed(const Duration(milliseconds: 800));
                            setState(() {
                              _isUploadingFront = false;
                              _frontIdUploaded = true;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildUploadCard(
                          title: _isHindi ? 'बैक साइड' : 'Back Side',
                          isUploaded: _backIdUploaded,
                          isLoading: _isUploadingBack,
                          onTap: () async {
                            setState(() => _isUploadingBack = true);
                            await Future.delayed(const Duration(milliseconds: 800));
                            setState(() {
                              _isUploadingBack = false;
                              _backIdUploaded = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Legal Self-Declaration Box
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _agreedToDeclaration
                            ? brightGold
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToDeclaration,
                          activeColor: brightGold,
                          checkColor: const Color(0xFF072420),
                          onChanged: (val) {
                            setState(() => _agreedToDeclaration = val ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(
                                () => _agreedToDeclaration = !_agreedToDeclaration,
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                _isHindi
                                    ? 'मैं घोषणा करता हूँ कि मैंने 18 वर्ष की आयु पूरी कर ली है और मैं अपने खाते के स्वतंत्र संचालन और कानूनी उत्तरदायित्व को स्वीकार करता हूँ।'
                                    : 'I solemnly declare that I am 18 years of age or older, and I accept full legal responsibility for my account independently under DPDP compliance.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: brandGold.withValues(alpha: 0.3),
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
                      onPressed: _isSubmitting ? null : _submitUpgrade,
                      child: _isSubmitting
                          ? SizedBox(
                              height: 22.h,
                              width: 22.h,
                              child: const CircularProgressIndicator(
                                color: Color(0xFF072420),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.how_to_reg_rounded,
                                  color: const Color(0xFF072420),
                                  size: 22.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _isHindi
                                      ? 'बालिग प्रमाणीकरण के लिए सबमिट करें'
                                      : 'Submit for Adult Verification',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF072420),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5.sp,
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
    );
  }

  Widget _buildUploadCard({
    required String title,
    required bool isUploaded,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          color: isUploaded
              ? const Color(0xFF00E676).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isUploaded ? const Color(0xFF00E676) : Colors.white24,
            style: isUploaded ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUploaded
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_outlined,
                    color: isUploaded
                        ? const Color(0xFF00E676)
                        : const Color(0xFFD4AF37),
                    size: 28.sp,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isUploaded ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    isUploaded
                        ? (_isHindi ? 'अपलोड हो गया' : 'Attached')
                        : (_isHindi ? 'टैप करें' : 'Tap to upload'),
                    style: GoogleFonts.outfit(
                      fontSize: 10.5.sp,
                      color: isUploaded
                          ? const Color(0xFF00E676)
                          : const Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 14.5.sp),
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13.sp),
      prefixIcon: Icon(icon, color: Colors.white60, size: 22.sp),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
        borderSide: const BorderSide(color: Color(0xFFC5A038), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5.w),
      ),
    );
  }
}
