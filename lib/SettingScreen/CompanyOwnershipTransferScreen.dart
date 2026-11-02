import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';
import 'package:track_loved/SettingScreen/CompanyTransferOtpVerifyScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/CompanyTransferSendOtpBodyModel.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

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
  String? _companyId;

  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();

  bool _confirmedHandover = false;
  bool _isLookingUpReceiver = false;
  bool _isReceiverNameReadOnly = false;
  String? _receiverLookupMessage;
  bool? _receiverExists;
  bool _isSendingOtp = false;
  Timer? _receiverPhoneDebounce;

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadCompanyInfo();
  }

  void _loadCompanyInfo() {
    try {
      final box = Hive.box('userdata');
      final userName = box.get('name', defaultValue: '')?.toString() ?? '';
      final userPhone = box.get('phone', defaultValue: '')?.toString() ?? '';
      final compPhone =
          box.get('companyPhone', defaultValue: '')?.toString() ?? '';

      final profileState = ref.read(getBussinessProfileProvider);
      final datum = profileState.asData?.value.data?.isNotEmpty == true
          ? profileState.asData!.value.data!.first
          : null;

      setState(() {
        _companyName = box.get('companyName', defaultValue: '') as String;
        if (_companyName.isEmpty && datum?.registeredCompanyName != null) {
          _companyName = datum!.registeredCompanyName!;
        }

        _companyType =
            box.get('companyType', defaultValue: 'Private Limited') as String;
        if (datum?.companyType != null && datum!.companyType!.isNotEmpty) {
          _companyType = datum.companyType!;
        }

        _currentPhone = compPhone.isNotEmpty ? compPhone : userPhone;
        if (_currentPhone.isEmpty && datum?.companyPhoneNumber != null) {
          _currentPhone = datum!.companyPhoneNumber!;
        }

        _companyGst = box.get('companyGst', defaultValue: '') as String;
        if (_companyGst.isEmpty && datum?.gstNumber != null) {
          _companyGst = datum!.gstNumber!;
        }

        _companyId = box.get('companyId')?.toString();
        if ((_companyId == null || _companyId!.isEmpty) && datum != null) {
          _companyId = datum.companyId ?? datum.id;
        }

        // Prefill sender details from Hive if available
        if (_senderNameController.text.isEmpty && userName.isNotEmpty) {
          _senderNameController.text = userName;
        }
        if (_senderPhoneController.text.isEmpty && _currentPhone.isNotEmpty) {
          _senderPhoneController.text = _currentPhone;
        }
      });
    } catch (_) {}
  }

  void _onReceiverPhoneChanged(String val) {
    _receiverPhoneDebounce?.cancel();
    final clean = val.trim();
    if (clean.length == 10 && RegExp(r'^[0-9]+$').hasMatch(clean)) {
      _receiverPhoneDebounce = Timer(const Duration(milliseconds: 350), () {
        _lookupReceiver(clean);
      });
    } else {
      if (_isReceiverNameReadOnly || _receiverLookupMessage != null) {
        setState(() {
          _isReceiverNameReadOnly = false;
          _receiverLookupMessage = null;
          _receiverExists = null;
        });
      }
    }
  }

  Future<void> _lookupReceiver(String phone) async {
    setState(() {
      _isLookingUpReceiver = true;
      _receiverLookupMessage = null;
      _receiverExists = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.lookupTransferReceiverData(phone);
      if (!mounted) return;

      setState(() {
        _isLookingUpReceiver = false;
        _receiverExists = res.exists;
        final receiverName = res.data?.name;
        if (res.exists == true && receiverName != null && receiverName.trim().isNotEmpty) {
          _receiverNameController.text = receiverName.trim();
          _isReceiverNameReadOnly = true;
          _receiverLookupMessage = _isHindi
              ? '✓ पंजीकृत उपयोगकर्ता: ${receiverName.trim()}'
              : '✓ Registered User Found: ${receiverName.trim()}';
        } else if (res.exists == true) {
          _isReceiverNameReadOnly = true;
          _receiverLookupMessage = _isHindi
              ? '✓ पंजीकृत उपयोगकर्ता मिला'
              : '✓ Registered User Found';
        } else {
          _isReceiverNameReadOnly = false;
          _receiverNameController.clear();
          _receiverLookupMessage = _isHindi
              ? 'ℹ️ नया उपयोगकर्ता (हस्तांतरण पर खाता स्वचालित रूप से बनाया जाएगा)'
              : 'ℹ️ New user (Account will be auto-created upon transfer)';
        }
      });
    } catch (e) {
      log('Error during receiver lookup: $e');
      if (!mounted) return;
      setState(() {
        _isLookingUpReceiver = false;
        _isReceiverNameReadOnly = false;
        _receiverExists = false;
        _receiverLookupMessage = _isHindi
            ? 'ℹ️ नया उपयोगकर्ता (हस्तांतरण पर खाता स्वचालित रूप से बनाया जाएगा)'
            : 'ℹ️ New user (Account will be auto-created upon transfer)';
      });
    }
  }

  String? _getCompanyId() {
    final profileData =
        ref.read(getBussinessProfileProvider).asData?.value.data;
    if (profileData != null && profileData.isNotEmpty) {
      final datum = profileData.first;
      final id = datum.companyId ?? datum.id;
      if (id != null && id.trim().isNotEmpty) {
        return id.trim();
      }
    }
    if (_companyId != null && _companyId!.trim().isNotEmpty) {
      return _companyId!.trim();
    }
    final fromHive = Hive.box('userdata').get('companyId')?.toString();
    if (fromHive != null && fromHive.trim().isNotEmpty) {
      return fromHive.trim();
    }
    return null;
  }

  @override
  void dispose() {
    _receiverPhoneDebounce?.cancel();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_confirmedHandover) {
      showErrorSnackBar(
        _isHindi
            ? 'कृपया आगे बढ़ने से पहले हस्तांतरण घोषणा चेकबॉक्स को चिह्नित करें।'
            : 'Please check the handover confirmation box before proceeding.',
      );
      return;
    }

    final sPhone = _senderPhoneController.text.trim();
    final rPhone = _receiverPhoneController.text.trim();

    if (sPhone == rPhone) {
      showErrorSnackBar(
        _isHindi
            ? 'भेजने वाले और प्राप्तकर्ता का फ़ोन नंबर समान नहीं हो सकता।'
            : 'Sender and receiver phone numbers cannot be the same.',
      );
      return;
    }

    final compId = _getCompanyId();
    if (compId == null || compId.isEmpty) {
      showErrorSnackBar(
        _isHindi
            ? 'कंपनी आईडी नहीं मिली। कृपया सुनिश्चित करें कि आपकी कंपनी प्रोफ़ाइल सक्रिय है।'
            : 'Company ID not found. Please ensure your company profile is active.',
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final authService = ref.read(authServiceProvider);
      final body = CompanyTransferSendOtpBodyModel(
        companyId: compId,
        senderPhone: sPhone,
      );
      await authService.sendCompanyTransferOtpData(body);

      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      showSuccessSnackBar(
        _isHindi
            ? 'सत्यापन OTP आपके नंबर $sPhone पर भेजा गया है (डेमो OTP: 123456)।'
            : 'Verification OTP sent to $sPhone (Demo OTP: 123456).',
      );

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyTransferOtpVerifyScreen(
            companyId: compId,
            senderName: _senderNameController.text.trim(),
            senderPhone: sPhone,
            receiverName: _receiverNameController.text.trim(),
            receiverPhone: rPhone,
            isHindi: _isHindi,
          ),
        ),
      );

      if (success == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      log('Error sending transfer OTP: $e');
      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      String errorMsg = _isHindi
          ? 'OTP भेजने में विफल। कृपया पुनः प्रयास करें।'
          : 'Failed to send OTP. Please try again.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        }
      }
      showErrorSnackBar(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    final businessProfileAsync = ref.watch(getBussinessProfileProvider);
    final datum = businessProfileAsync.asData?.value.data?.isNotEmpty == true
        ? businessProfileAsync.asData!.value.data!.first
        : null;

    final displayCompanyName = datum?.registeredCompanyName?.trim().isNotEmpty == true
        ? datum!.registeredCompanyName!.trim()
        : (_companyName.trim().isNotEmpty
            ? _companyName.trim()
            : 'Registered Corporate Profile');

    final displayCompanyType = datum?.companyType?.trim().isNotEmpty == true
        ? datum!.companyType!.trim()
        : (_companyType.trim().isNotEmpty
            ? _companyType.trim()
            : 'Public Limited / Corporate');

    final displayGst = datum?.gstNumber?.trim().isNotEmpty == true
        ? datum!.gstNumber!.trim()
        : _companyGst.trim();

    final displayPhone = datum?.companyPhoneNumber?.trim().isNotEmpty == true
        ? datum!.companyPhoneNumber!.trim()
        : _currentPhone.trim();

    final displayCompanyId = datum?.companyId ?? datum?.id ?? _companyId;

    // Keep Hive & controller synchronized whenever network datum is loaded
    ref.listen(getBussinessProfileProvider, (prev, next) {
      final newDatum = next.asData?.value.data?.isNotEmpty == true
          ? next.asData!.value.data!.first
          : null;
      if (newDatum != null) {
        if (_senderPhoneController.text.isEmpty &&
            newDatum.companyPhoneNumber?.isNotEmpty == true) {
          _senderPhoneController.text = newDatum.companyPhoneNumber!;
        }
        try {
          final box = Hive.box('userdata');
          if (newDatum.registeredCompanyName != null) {
            box.put('companyName', newDatum.registeredCompanyName);
          }
          if (newDatum.companyType != null) {
            box.put('companyType', newDatum.companyType);
          }
          if (newDatum.gstNumber != null) {
            box.put('companyGst', newDatum.gstNumber);
          }
          if (newDatum.companyPhoneNumber != null) {
            box.put('companyPhone', newDatum.companyPhoneNumber);
          }
          final id = newDatum.companyId ?? newDatum.id;
          if (id != null) {
            box.put('companyId', id);
          }
        } catch (_) {}
      }
    });

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
                    _isHindi
                        ? 'वर्तमान कंपनी विवरण'
                        : 'Current Company Overview',
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
                    child: businessProfileAsync.isLoading && datum == null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: brightGold,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    _isHindi
                                        ? 'कंपनी विवरण लोड हो रहा है...'
                                        : 'Loading company overview...',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    color: brightGold,
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      displayCompanyName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (datum?.status != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        border: Border.all(
                                          color: const Color(0xFF00E676),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        datum!.status!.toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF00E676),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$displayCompanyType • ${displayGst.isNotEmpty ? 'GST: $displayGst' : 'Active Profile'}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (displayPhone.isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      color: Colors.white54,
                                      size: 14.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${_isHindi ? 'वर्तमान एडमिन फ़ोन:' : 'Current Admin Phone:'} $displayPhone',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (displayCompanyId != null &&
                                  displayCompanyId.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tag_rounded,
                                      color: Colors.white38,
                                      size: 13.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'ID: $displayCompanyId',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.sp,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                  ),
                  SizedBox(height: 22.h),

                  // 1. Sender Details Form
                  Text(
                    _isHindi
                        ? '1. भेजने वाले का विवरण (Sender Details)'
                        : '1. Sender Details (Current Owner)',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                      color: brightGold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Sender Full Name (send name)
                  TextFormField(
                    controller: _senderNameController,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15.sp,
                    ),
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'भेजने वाले का नाम (Send Name) *'
                          : 'Sender Name (Send Name) *',
                      hint: _isHindi
                          ? 'भेजने वाले का पूरा नाम दर्ज करें'
                          : 'Enter sender full name',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया भेजने वाले का नाम दर्ज करें'
                            : 'Please enter sender name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),
                  // Sender Phone Number (send number)
                  TextFormField(
                    controller: _senderPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15.sp,
                    ),
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'भेजने वाले का नंबर (Send Number) *'
                          : 'Sender Phone Number (Send Number) *',
                      hint: '10-digit mobile number',
                      icon: Icons.phone_android_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया भेजने वाले का फ़ोन नंबर दर्ज करें'
                            : 'Please enter sender phone number';
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
                  SizedBox(height: 22.h),
                  // 2. Receiver Details Form
                  Text(
                    _isHindi
                        ? '2. प्राप्तकर्ता का विवरण (Receiver Details)'
                        : '2. Receiver Details (New Owner)',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                      color: brightGold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Receiver Phone Number (reciever ka number) - Enter first for autofill check
                  TextFormField(
                    controller: _receiverPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15.sp,
                    ),
                    onChanged: _onReceiverPhoneChanged,
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'प्राप्तकर्ता का नंबर (Receiver Number) *'
                          : 'Receiver Phone Number (Receiver Number) *',
                      hint: '10-digit mobile number',
                      icon: Icons.phone_android_rounded,
                      suffixIcon: _isLookingUpReceiver
                          ? Padding(
                              padding: EdgeInsets.all(14.r),
                              child: SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFC5A038),
                                ),
                              ),
                            )
                          : (_receiverExists == true
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF00E676),
                                  size: 22.sp,
                                )
                              : (_receiverExists == false
                                  ? Icon(
                                      Icons.person_add_alt_1_rounded,
                                      color: Colors.orangeAccent,
                                      size: 22.sp,
                                    )
                                  : null)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया प्राप्तकर्ता का फ़ोन नंबर दर्ज करें'
                            : 'Please enter receiver phone number';
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

                  // Receiver Full Name (reciever ka name) - Autofilled & locked if exists: true
                  TextFormField(
                    controller: _receiverNameController,
                    readOnly: _isReceiverNameReadOnly,
                    style: GoogleFonts.outfit(
                      color: _isReceiverNameReadOnly
                          ? const Color(0xFF00E676)
                          : Colors.white,
                      fontSize: 15.sp,
                      fontWeight: _isReceiverNameReadOnly
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    decoration: _inputDecoration(
                      label: _isHindi
                          ? 'प्राप्तकर्ता का नाम (Receiver Name) *'
                          : 'Receiver Name (Receiver Name) *',
                      hint: _isHindi
                          ? 'प्राप्तकर्ता का पूरा नाम दर्ज करें'
                          : 'Enter receiver full name',
                      icon: Icons.person_add_rounded,
                      suffixIcon: _isReceiverNameReadOnly
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: const Color(0xFF00E676),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                              ],
                            )
                          : null,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isHindi
                            ? 'कृपया प्राप्तकर्ता का नाम दर्ज करें'
                            : 'Please enter receiver name';
                      }
                      return null;
                    },
                  ),

                  // Lookup status message banner
                  if (_receiverLookupMessage != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _receiverExists == true
                            ? const Color(0xFF00E676).withValues(alpha: 0.12)
                            : Colors.orangeAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _receiverExists == true
                              ? const Color(0xFF00E676).withValues(alpha: 0.4)
                              : Colors.orangeAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _receiverExists == true
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            size: 15.sp,
                            color: _receiverExists == true
                                ? const Color(0xFF00E676)
                                : Colors.orangeAccent,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              _receiverLookupMessage!,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5.sp,
                                color: _receiverExists == true
                                    ? const Color(0xFF00E676)
                                    : Colors.orangeAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),

                  // Confirmation Agreement Checkbox
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _confirmedHandover ? brightGold : Colors.white12,
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
                              setState(
                                () => _confirmedHandover = !_confirmedHandover,
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                _isHindi
                                    ? 'मैं पुष्टि करता हूँ कि मैं इस कंपनी का स्वामित्व ऊपर दिए गए प्राप्तकर्ता को सौंपना चाहता हूँ। हस्तांतरण पूरा करने से पहले मेरे भेजने वाले नंबर पर सत्यापन OTP भेजा जाएगा।'
                                    : 'I confirm that I am transferring ownership to the designated receiver above. An OTP will be sent to my sender number for verification before transfer.',
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

                  // Submit Button - Send OTP
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
                      onPressed: _isSendingOtp ? null : _confirmTransfer,
                      child: _isSendingOtp
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
                                  Icons.send_rounded,
                                  color: const Color(0xFF072420),
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _isHindi
                                      ? 'OTP भेजें (Send OTP)'
                                      : 'Send OTP',
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
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      counterText: '',
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
