import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';

class CompanyOwnershipTransferScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const CompanyOwnershipTransferScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<CompanyOwnershipTransferScreen> createState() =>
      _CompanyOwnershipTransferScreenState();
}

class _CompanyOwnershipTransferScreenState
    extends ConsumerState<CompanyOwnershipTransferScreen> {
  late bool _isHindi;
  final _formKey = GlobalKey<FormState>();

  String _companyName = '';
  String _companyType = '';
  String _currentPhone = '';
  String _companyGst = '';

  final TextEditingController _newAdminNameController = TextEditingController();
  final TextEditingController _newAdminPhoneController = TextEditingController();
  final TextEditingController _newAdminEmailController = TextEditingController();
  final TextEditingController _handoverNotesController = TextEditingController();

  String _selectedRole = 'Corporate Super Admin';
  String _selectedReason = 'Leaving Company Permanently';
  bool _confirmedHandover = false;
  bool _isSubmitting = false;

  final List<String> _roles = [
    'Corporate Super Admin',
    'Primary Contact Person',
    'Managing Partner / Director',
    'Authorized Signatory',
  ];

  final List<String> _departureReasons = [
    'Leaving Company Permanently',
    'Role Resignation & Handover',
    'Organizational Restructuring',
    'Founder Succession',
    'Department Delegation',
  ];

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadCompanyInfo();
  }

  void _loadCompanyInfo() {
    try {
      final box = Hive.box('userdata');
      setState(() {
        _companyName = box.get('companyName', defaultValue: '') as String;
        _companyType =
            box.get('companyType', defaultValue: 'Private Limited') as String;
        _currentPhone = box.get('companyPhone', defaultValue: '') as String;
        _companyGst = box.get('companyGst', defaultValue: '') as String;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _newAdminNameController.dispose();
    _newAdminPhoneController.dispose();
    _newAdminEmailController.dispose();
    _handoverNotesController.dispose();
    super.dispose();
  }

  void _confirmTransfer() {
    if (!_formKey.currentState!.validate()) return;

    if (!_confirmedHandover) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'कृपया आगे बढ़ने से पहले स्वामित्व हस्तांतरण की पुष्टि करें।'
                : 'Please check the handover declaration box before transferring.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent.shade700,
        ),
      );
      return;
    }

    final newName = _newAdminNameController.text.trim();
    final newPhone = _newAdminPhoneController.text.trim();

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
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 26,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi ? 'हस्तांतरण की पुष्टि करें?' : 'Confirm Permanent Handover?',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isHindi
                  ? 'क्या आप निश्चित हैं कि आप इस कंपनी का स्वामित्व $newName को सौंपना चाहते हैं?\n\nनया संपर्क नंबर: $newPhone\n\nएक बार हस्तांतरित होने के बाद, आपका प्रशासनिक नियंत्रण समाप्त हो जाएगा और नया नंबर कंपनी का प्राथमिक संपर्क नंबर बन जाएगा।'
                  : 'Are you sure you want to permanently transfer ownership of this company to $newName?\n\nNew Company Contact: $newPhone\n\nOnce transferred, your administrative access will be transferred and the company contact number will be officially updated.',
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isHindi ? 'रद्द करें' : 'Cancel',
              style: GoogleFonts.outfit(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeTransfer();
            },
            child: Text(
              _isHindi ? 'हाँ, हस्तांतरित करें' : 'Yes, Transfer',
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

  void _executeTransfer() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1400));

    final newName = _newAdminNameController.text.trim();
    final newPhone = _newAdminPhoneController.text.trim();
    final newEmail = _newAdminEmailController.text.trim();

    try {
      final box = Hive.box('userdata');
      // Update primary company phone to the new admin's phone!
      await box.put('companyPhone', newPhone);
      await box.put('company_account_assigned', true);
      await box.put('company_assigned_admin_name', newName);
      await box.put('company_assigned_admin_contact', newPhone);
      await box.put('company_assigned_admin_email', newEmail);
      await box.put('company_assigned_admin_role', _selectedRole);
      await box.put('company_handover_reason', _selectedReason);
      await box.put('company_ownership_transferred', true);

      ref.invalidate(getBussinessProfileProvider);
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
              Icons.check_circle_rounded,
              color: Color(0xFF00E676),
              size: 26,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi
                    ? 'स्वामित्व सफलतापूर्वक हस्तांतरित!'
                    : 'Ownership Successfully Transferred!',
                style: GoogleFonts.outfit(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isHindi
              ? 'कंपनी का स्वामित्व $newName को सौंप दिया गया है और आधिकारिक संपर्क नंबर $newPhone पर अपडेट कर दिया गया है।'
              : 'Company ownership has been successfully delegated to $newName and the official contact phone number has been updated to $newPhone.',
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
          _isHindi ? 'कंपनी स्वामित्व हस्तांतरण' : 'Company Ownership Transfer',
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
                  // Departure Banner
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.swap_horizontal_circle_rounded,
                          color: Colors.orangeAccent,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi
                                    ? 'कंपनी छोड़ने एवं उत्तराधिकारी को सौंपने की प्रक्रिया'
                                    : 'Permanent Handover & Admin Transfer',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                _isHindi
                                    ? 'यदि आप कंपनी छोड़ रहे हैं, तो कंपनी का पूर्ण नियंत्रण और प्राथमिक संपर्क नंबर नए व्यक्ति को सौंपें।'
                                    : 'When permanently leaving the company, assign complete administrative control and update the official contact number to the new representative.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Current Company Overview Card
                  Text(
                    _isHindi ? 'वर्तमान कंपनी विवरण' : 'Current Company Overview',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                      color: brightGold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business_rounded, color: brightGold, size: 22.sp),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                _companyName.isNotEmpty
                                    ? _companyName
                                    : 'Registered Corporate Profile',
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Text(
                              '$_companyType • ${_companyGst.isNotEmpty ? 'GST: $_companyGst' : 'Active Profile'}',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        if (_currentPhone.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, color: Colors.white54, size: 14.sp),
                              SizedBox(width: 6.w),
                              Text(
                                '${_isHindi ? 'वर्तमान एडमिन फ़ोन:' : 'Current Admin Phone:'} $_currentPhone',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // New Admin Details Form
                  Text(
                    _isHindi ? 'नए एडमिन एवं उत्तराधिकारी का विवरण' : 'New Administrator (Successor) Details',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                      color: brightGold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // New Admin Full Name
                  TextFormField(
                    controller: _newAdminNameController,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    decoration: _inputDecoration(
                      label: _isHindi ? 'नए एडमिन का पूरा नाम *' : 'New Admin Full Name *',
                      hint: 'e.g., Rajesh Kumar Sharma',
                      icon: Icons.person_add_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया नए एडमिन का नाम दर्ज करें'
                            : 'Please enter new administrator name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // New Admin Phone (Will become official company phone)
                  TextFormField(
                    controller: _newAdminPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'नया कंपनी एडमिन फ़ोन नंबर *'
                          : 'New Company Admin Phone Number *',
                      hint: '10-digit mobile number',
                      icon: Icons.phone_android_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया फ़ोन नंबर दर्ज करें'
                            : 'Please enter phone number';
                      }
                      if (val.trim().length != 10 ||
                          !RegExp(r'^[0-9]+$').hasMatch(val.trim())) {
                        return _isHindi
                            ? 'कृपया 10 अंकों का मान्य फ़ोन नंबर दर्ज करें'
                            : 'Enter valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // New Admin Email
                  TextFormField(
                    controller: _newAdminEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'नए एडमिन का ईमेल पता *'
                          : 'New Admin Official Email *',
                      hint: 'e.g., admin@company.com',
                      icon: Icons.email_outlined,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया ईमेल दर्ज करें'
                            : 'Please enter email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val.trim())) {
                        return _isHindi
                            ? 'मान्य ईमेल दर्ज करें'
                            : 'Enter valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    dropdownColor: const Color(0xFF072420),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    iconEnabledColor: brightGold,
                    decoration: _inputDecoration(
                      label: _isHindi ? 'सौंपी गई भूमिका *' : 'Assigned Role *',
                      hint: 'Select role',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    items: _roles.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r, style: GoogleFonts.outfit(fontSize: 14.sp)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Departure Reason Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    dropdownColor: const Color(0xFF072420),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15.sp),
                    iconEnabledColor: brightGold,
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'हस्तांतरण का कारण *'
                          : 'Reason for Transfer / Departure *',
                      hint: 'Select reason',
                      icon: Icons.exit_to_app_rounded,
                    ),
                    items: _departureReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason, style: GoogleFonts.outfit(fontSize: 14.sp)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                  SizedBox(height: 20.h),

                  // Confirmation Agreement Checkbox
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _confirmedHandover
                            ? brightGold
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _confirmedHandover,
                          activeColor: brightGold,
                          checkColor: const Color(0xFF072420),
                          onChanged: (val) {
                            setState(() => _confirmedHandover = val ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _confirmedHandover = !_confirmedHandover);
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                _isHindi
                                    ? 'मैं पुष्टि करता हूँ कि मैं कंपनी छोड़ रहा हूँ और इस कंपनी प्रोफ़ाइल का प्राथमिक नियंत्रण और फ़ोन नंबर नए व्यवस्थापक को सौंप रहा हूँ।'
                                    : 'I confirm that I am permanently transferring ownership and company contact phone number to the new administrator designated above.',
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

                  // Submit Transfer Button
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
                      onPressed: _isSubmitting ? null : _confirmTransfer,
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
                                  Icons.swap_horiz_rounded,
                                  color: const Color(0xFF072420),
                                  size: 24.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _isHindi
                                      ? 'स्वामित्व सौंपें एवं नंबर बदलें'
                                      : 'Transfer Ownership & Update Number',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF072420),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      counterText: '',
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 14.5.sp),
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13.sp),
      prefixIcon: Icon(icon, color: Colors.white60, size: 22.sp),
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
