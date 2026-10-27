import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/LoginScreen/DpdpaPolicyDialog.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/LoginScreen/OtpVerifyScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameConatroller = TextEditingController();
  final _phoneConatroller = TextEditingController();

  final _parentPhoneController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  String? _selectedAccountType; // "adult" (18+) or "child" (<18)
  bool _agreedToTerms = false;
  DpdpaConsentResult? _dpdpaConsent;

  Future<void> _showDpdpaPolicyDialog() async {
    final result = await showDialog<DpdpaConsentResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DpdpaPolicyDialog(
        initialLanguageCode: _dpdpaConsent?.languageCode ?? 'en',
        initialLocationConsent:
            _dpdpaConsent?.consentLocationAndProfile ?? _agreedToTerms,
        initialMarketplaceConsent: _dpdpaConsent?.consentMarketplace ?? false,
        initialContactsConsent: _dpdpaConsent?.consentContacts ?? false,
        initialParentalConsent: _selectedAccountType == 'child'
            ? (_dpdpaConsent?.parentalDeclaration ?? true)
            : (_dpdpaConsent?.parentalDeclaration ?? false),
      ),
    );

    if (result != null && result.agreed) {
      setState(() {
        _dpdpaConsent = result;
        _agreedToTerms = result.consentLocationAndProfile;
      });
    }
  }

  @override
  void dispose() {
    _nameConatroller.dispose();
    _emailController.dispose();
    _phoneConatroller.dispose();
    _parentPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F3D38),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          size: 54.sp,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Join TrackLovedOnes',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Create an account to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Account Type Selector (Adult 18+ vs Child Under 18)
                      DropdownButtonFormField<String>(
                        value: _selectedAccountType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F3D38),
                        decoration: InputDecoration(
                          labelText: 'Account Type',
                          hintText: 'Select Account Type',
                          labelStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 15.5.sp,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 16.h,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: _selectedAccountType == 'child'
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFD4AF37),
                              width: 1.2,
                            ),
                          ),
                        ),

                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFFD4AF37),
                          size: 24.sp,
                        ),

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),

                        hint: Text(
                          'Select Account Type',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'child',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.child_care,
                                  color: const Color(0xFF00E676),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 10.w),
                                Flexible(
                                  child: Text(
                                    'Child (Under 18 Years - Parental Gate)',
                                    style: TextStyle(
                                      color: const Color(0xFF00E676),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'user',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: const Color(0xFFD4AF37),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 10.w),
                                const Text('User'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'company',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  color: const Color(0xFFD4AF37),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 10.w),
                                const Text('Company'),
                              ],
                            ),
                          ),
                        ],

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select account type';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountType = value;
                          });
                        },
                      ),
                      SizedBox(height: 18.h),

                      customTextField(
                        controller: _nameConatroller,
                        labelText: _selectedAccountType == 'child'
                            ? "Child's Full Name"
                            : 'Enter Your Name',
                        hintText: _selectedAccountType == 'child'
                            ? "Enter child's full name"
                            : 'Enter your name',
                        prefixIcon: Icons.person,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _selectedAccountType == 'child'
                                ? "Please enter child's name"
                                : 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 18.h),

                      customTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'Enter email address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 18.h),

                      customTextField(
                        controller: _phoneConatroller,
                        labelText: _selectedAccountType == 'child'
                            ? "Child's Phone Number (SIM Device)"
                            : 'Phone Number',
                        hintText: _selectedAccountType == 'child'
                            ? "Enter child's mobile number"
                            : 'Enter phone number',
                        prefixIcon: Icons.call,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _selectedAccountType == 'child'
                                ? "Please enter child's phone number"
                                : 'Please enter phone number';
                          }
                          return null;
                        },
                      ),

                      // If Child: show Parent/Guardian Phone input and parental consent note
                      if (_selectedAccountType == 'child') ...[
                        SizedBox(height: 18.h),
                        customTextField(
                          controller: _parentPhoneController,
                          labelText: 'Parent / Guardian Phone Number',
                          hintText: "Enter parent's 10-digit phone number",
                          prefixIcon: Icons.family_restroom,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (_selectedAccountType == 'child') {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter parent/guardian phone number";
                              }
                              if (value.trim().length < 10) {
                                return "Please enter a valid 10-digit phone number";
                              }
                              if (value.trim() ==
                                  _phoneConatroller.text.trim()) {
                                return "Parent phone must be different from child's phone";
                              }
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: const Color(
                                0xFF00E676,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: const Color(0xFF00E676),
                                size: 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  "Parental Permission Required: A verification OTP will be sent to the parent's phone to verify and authorize setup under DPDPA Section 9.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5.sp,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 18.h),

                      customTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !isPasswordVisible,
                        showVisibilityIcon: true,
                        onVisibilityTap: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.trim().length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Terms & Conditions (DPDPA) Consent Row
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 24.h,
                              width: 24.w,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: const Color(0xFF00E676),
                                checkColor: Colors.black,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                onChanged: (val) {
                                  if (val == true) {
                                    _showDpdpaPolicyDialog();
                                  } else {
                                    setState(() {
                                      _agreedToTerms = false;
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showDpdpaPolicyDialog,
                                child: RichText(
                                  text: TextSpan(
                                    text: 'I agree to ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.sp,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: const Color(0xFFD4AF37),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      const TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy (DPDPA)',
                                        style: TextStyle(
                                          color: const Color(0xFFD4AF37),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                size: 18.sp,
                                color: const Color(0xFFD4AF37),
                              ),
                              tooltip: 'Read & Change Language',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _showDpdpaPolicyDialog,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // Sign Up Button matching LoginScreen style
                      Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  if (!_agreedToTerms) {
                                    showErrorSnackBar(
                                      'Please accept the Terms & Conditions and Privacy Policy to proceed',
                                    );
                                    _showDpdpaPolicyDialog();
                                    return;
                                  }
                                  try {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    final service = ref.read(
                                      authServiceProvider,
                                    );
                                    final response = await service.registerData(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      name: _nameConatroller.text.trim(),
                                      phone: _phoneConatroller.text.trim(),
                                      role: _selectedAccountType == 'child'
                                          ? 'child'
                                          : _selectedAccountType == 'company'
                                          ? 'company'
                                          : 'user',
                                      parentPhone:
                                          _selectedAccountType == 'child'
                                          ? _parentPhoneController.text.trim()
                                          : null,
                                    );
                                    if (response.success == true) {
                                      showSuccessSnackBar(
                                        response.message ??
                                            (_selectedAccountType == 'child'
                                                ? "Parental verification OTP sent successfully"
                                                : "OTP sent successfully"),
                                      );
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OtpVerifyScreen(
                                                  email: _emailController.text
                                                      .trim(),
                                                  phone: _phoneConatroller.text
                                                      .trim(),
                                                  parentPhone:
                                                      _selectedAccountType ==
                                                          'child'
                                                      ? _parentPhoneController
                                                            .text
                                                            .trim()
                                                      : null,
                                                  isChild:
                                                      _selectedAccountType ==
                                                      'child',
                                                ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    log(e.toString());
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
                          child: isLoading
                              ? Center(
                                  child: SizedBox(
                                    width: 24.w,
                                    height: 24.h,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5.w,
                                    ),
                                  ),
                                )
                              : Text(
                                  'SEND VERIFICATION CODE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16.5.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Already have an account row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15.5.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: const Color(0xFFD4AF37),
                                fontSize: 15.5.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
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

  Widget customTextField({
    required TextEditingController controller,
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    VoidCallback? onVisibilityTap,
    bool showVisibilityIcon = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 15.5.sp),
        hintStyle: TextStyle(fontSize: 15.sp, color: Colors.white38),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.white60, size: 24.sp)
            : null,
        suffixIcon: showVisibilityIcon
            ? IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 44.w, minHeight: 46.h),
                onPressed: onVisibilityTap,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22.sp,
                  color: Colors.white,
                ),
              )
            : null,
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
        errorStyle: TextStyle(fontSize: 13.sp),
      ),
    );
  }
}
