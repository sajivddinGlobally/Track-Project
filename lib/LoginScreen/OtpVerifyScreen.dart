import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();

  String otp = '';
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _timer;
  bool isLoading = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0F3D38);
    const accentGold = Color(0xFFC5A038);

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: accentGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentGold.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: accentGold.withValues(alpha: 0.6)),
      ),
    );
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'OTP Verification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryDark,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Icon Badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.phonelink_lock_rounded,
                    color: accentGold,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Verification Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    text: 'We have sent a 6-digit verification code to\n',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: widget.email.isNotEmpty
                            ? widget.email
                            : 'your registered email address',
                        style: const TextStyle(
                          color: accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter 6-Digit OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Pinput Field
                Pinput(
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  showCursor: true,
                  cursor: Container(width: 2, height: 24, color: accentGold),
                  onChanged: (value) {
                    setState(() {
                      otp = value;
                    });
                    debugPrint('OTP: $otp');
                  },
                  onCompleted: (value) {
                    setState(() {
                      otp = value;
                    });
                    debugPrint('Complete OTP: $otp');
                  },
                ),
                const SizedBox(height: 24),

                // Resend Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    _canResend
                        ? GestureDetector(
                            onTap: () async {
                              try {
                                setState(() {
                                  isResending = false;
                                });
                                final service = ref.read(authServiceProvider);
                                final response = await service
                                    .forgetPasswordData(email: widget.email);
                                if (response.success == true) {
                                  if (response.success == true) {
                                    _startTimer();
                                    showSuccessSnackBar(
                                      "OTP Resent Sucessfully",
                                    );
                                  }
                                }
                              } catch (e) {
                                log(e.toString());
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isResending = false;
                                  });
                                }
                              }
                            },
                            child: isResending
                                ? SizedBox(
                                    width: 15.w,
                                    height: 15.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                    ),
                                  )
                                : Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      color: accentGold,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: accentGold,
                                    ),
                                  ),
                          )
                        : Text(
                            'Resend in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: accentGold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (otp.length < 6) {
                        showErrorSnackBar(
                          "Please enter the complete 6-digit OTP",
                        );
                        return;
                      }
                      bool isNavigating = false;
                      try {
                        setState(() {
                          isLoading = true;
                        });
                        final service = ref.read(authServiceProvider);
                        final response = await service.otpData(
                          email: widget.email,
                          otp: otp,
                        );
                        if (response.success == true) {
                          showSuccessSnackBar(response.message ?? "Success");
                          var box = Hive.box("userdata");
                          if (response.data?.token != null) {
                            await box.put("token", response.data!.token);
                          }
                          if (response.data?.user?.id != null) {
                            await box.put("id", response.data!.user!.id);
                          }
                          if (response.data?.user?.name != null) {
                            await box.put("name", response.data!.user!.name);
                          }
                          await box.put(
                            "isProfileComplete",
                            response.data?.user?.isProfileComplete,
                          );
                          await box.put("email", response.data?.user?.email);

                          if (context.mounted) {
                            isNavigating = true;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegistrationConsentScreen(),
                              ),
                              (route) => false,
                            );
                            return;
                          }
                        } else {
                          if (mounted) {
                            setState(() {
                              otp = "";
                              _otpController.clear();
                            });
                          }
                        }
                      } catch (e) {
                        log(e.toString());
                        if (mounted) {
                          setState(() {
                            otp = "";
                            _otpController.clear();
                          });
                        }
                      } finally {
                        if (mounted && !isNavigating) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGold,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Text(
                            'VERIFY & CONTINUE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
