import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:pinput/pinput.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/CompanyTransferSendOtpBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/CompanyTransferExecuteBodyModel.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class CompanyTransferOtpVerifyScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final bool isHindi;

  const CompanyTransferOtpVerifyScreen({
    super.key,
    required this.companyId,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    this.isHindi = false,
  });

  @override
  ConsumerState<CompanyTransferOtpVerifyScreen> createState() =>
      _CompanyTransferOtpVerifyScreenState();
}

class _CompanyTransferOtpVerifyScreenState
    extends ConsumerState<CompanyTransferOtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();

  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showSuccessSnackBar(
        widget.isHindi
            ? 'सत्यापन OTP आपके नंबर ${widget.senderPhone} पर भेजा गया है (डेमो OTP: 123456)।'
            : 'Verification OTP sent to your number ${widget.senderPhone} (Demo OTP: 123456).',
      );
    });
  }

  void _startTimer() {
    if (!mounted) return;
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isResending) return;
    setState(() => _isResending = true);
    try {
      final authService = ref.read(authServiceProvider);
      final body = CompanyTransferSendOtpBodyModel(
        companyId: widget.companyId,
        senderPhone: widget.senderPhone,
      );
      await authService.sendCompanyTransferOtpData(body);
      if (!mounted) return;
      setState(() => _isResending = false);
      _startTimer();
      showSuccessSnackBar(
        widget.isHindi
            ? 'नया OTP आपके नंबर ${widget.senderPhone} पर पुनः भेजा गया है (डेमो OTP: 123456)।'
            : 'New OTP resent to ${widget.senderPhone} (Demo OTP: 123456).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      String errorMsg = widget.isHindi
          ? 'OTP पुनः भेजने में विफल।'
          : 'Failed to resend OTP.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        }
      }
      showErrorSnackBar(errorMsg);
    }
  }

  Future<void> _verifyAndTransfer() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      showErrorSnackBar(
        widget.isHindi
            ? 'कृपया 6 अंकों का मान्य OTP दर्ज करें।'
            : 'Please enter the complete 6-digit OTP.',
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final authService = ref.read(authServiceProvider);
      final body = CompanyTransferExecuteBodyModel(
        companyId: widget.companyId,
        senderPhone: widget.senderPhone,
        senderOtp: code,
        receiverPhone: widget.receiverPhone,
        receiverName: widget.receiverName,
      );
      await authService.executeCompanyTransferData(body);

      final box = Hive.box('userdata');
      // Update official primary company phone to receiver
      await box.put('companyPhone', widget.receiverPhone);
      await box.put('company_account_assigned', true);
      await box.put('company_assigned_admin_name', widget.receiverName);
      await box.put('company_assigned_admin_contact', widget.receiverPhone);
      await box.put('company_previous_owner_name', widget.senderName);
      await box.put('company_previous_owner_contact', widget.senderPhone);
      await box.put('company_ownership_transferred', true);

      ref.invalidate(getBussinessProfileProvider);

      if (!mounted) return;
      setState(() => _isVerifying = false);

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);

      String errorMsg = widget.isHindi
          ? 'कंपनी हस्तांतरण विफल रहा। कृपया पुनः प्रयास करें।'
          : 'Company transfer failed. Please try again.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        }
      }
      showErrorSnackBar(errorMsg);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF072420),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFC5A038), width: 1.2),
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
                widget.isHindi
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isHindi
                  ? 'कंपनी का पूर्ण स्वामित्व ${widget.receiverName} को सौंप दिया गया है और आधिकारिक कंपनी नंबर ${widget.receiverPhone} पर अपडेट हो गया है।'
                  : 'Company ownership has been successfully delegated to ${widget.receiverName} and the official company contact number has been updated to ${widget.receiverPhone}.',
              style: GoogleFonts.outfit(
                fontSize: 13.5.sp,
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ],
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
              widget.isHindi ? 'पूर्ण' : 'Done',
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
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 54.h,
      textStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white24),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: brightGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: brightGold.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

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
          widget.isHindi ? 'OTP सत्यापन' : 'Verify Sender OTP',
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
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10.h),

                // Shield Icon Container
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: brightGold.withValues(alpha: 0.15),
                    border: Border.all(
                      color: brightGold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 38.sp,
                      color: brightGold,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Title
                Text(
                  widget.isHindi
                      ? 'स्वामित्व हस्तांतरण सत्यापन'
                      : 'Transfer Verification',
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  widget.isHindi
                      ? 'सुरक्षा कारणों से, कंपनी स्वामित्व सौंपने से पहले आपके फ़ोन नंबर पर 6-अंकों का OTP भेजा गया है:'
                      : 'For corporate security, enter the 6-digit verification OTP sent to your registered sender phone number:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5.sp,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),

                // Phone Display Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: brightGold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_android_rounded, size: 16.sp, color: brightGold),
                      SizedBox(width: 6.w),
                      Text(
                        '+91 ${widget.senderPhone}',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: brightGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Transfer Handover Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isHindi ? 'भेजने वाला (Sender)' : 'Sender (Current)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5.sp,
                                    color: Colors.white54,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  widget.senderName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.senderPhone,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: brightGold.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: brightGold,
                              size: 18.sp,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.isHindi ? 'प्राप्तकर्ता (Receiver)' : 'Receiver (New)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5.sp,
                                    color: Colors.white54,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  widget.receiverName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.receiverPhone,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    color: Colors.white70,
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

                // OTP Pinput
                Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  showCursor: true,
                  keyboardType: TextInputType.number,
                  onCompleted: (_) {
                    _verifyAndTransfer();
                  },
                ),
                SizedBox(height: 20.h),

                // Resend Timer & Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_canResend) ...[
                      Icon(Icons.timer_outlined, size: 16.sp, color: Colors.white54),
                      SizedBox(width: 6.w),
                      Text(
                        widget.isHindi
                            ? 'OTP पुनः भेजें: ${_secondsRemaining}s'
                            : 'Resend OTP in ${_secondsRemaining}s',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: brightGold,
                                ),
                              )
                            : Text(
                                widget.isHindi ? 'OTP पुनः भेजें' : 'Resend OTP',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: brightGold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: brightGold,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 30.h),

                // Testing Demo OTP Note
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 14.sp,
                          color: brightGold,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          widget.isHindi
                              ? 'परीक्षण डेमो OTP: 123456'
                              : 'Testing Demo OTP: 123456',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: brightGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Transfer Company Button
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
                    onPressed: _isVerifying ? null : _verifyAndTransfer,
                    child: _isVerifying
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
                                Icons.check_circle_outline_rounded,
                                color: const Color(0xFF072420),
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                widget.isHindi
                                    ? 'कंपनी हस्तांतरित करें (Transfer Company)'
                                    : 'Transfer Company',
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
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
