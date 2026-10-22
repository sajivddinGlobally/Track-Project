import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/ForgotPasswordScreen.dart';
import 'package:track_loved/LoginScreen/RegisterScreen.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool rememberMe = false;

  // Keychain / Keystore backed, and separate from Hive so that logout
  // (which clears Hive) does not wipe the remembered login.
  static const _secureStorage = FlutterSecureStorage();
  static const _kRemember = 'remember_me';
  static const _kEmail = 'remember_email';
  static const _kPassword = 'remember_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      if (await _secureStorage.read(key: _kRemember) != 'true') return;
      final email = await _secureStorage.read(key: _kEmail) ?? '';
      final password = await _secureStorage.read(key: _kPassword) ?? '';
      if (!mounted) return;
      setState(() {
        rememberMe = true;
        _emailController.text = email;
        _passwordController.text = password;
      });
    } catch (e) {
      log('Could not read saved credentials: $e');
    }
  }

  Future<void> _saveOrClearCredentials() async {
    try {
      if (rememberMe) {
        await _secureStorage.write(key: _kRemember, value: 'true');
        await _secureStorage.write(
          key: _kEmail,
          value: _emailController.text.trim(),
        );
        await _secureStorage.write(
          key: _kPassword,
          value: _passwordController.text.trim(),
        );
      } else {
        await _secureStorage.delete(key: _kRemember);
        await _secureStorage.delete(key: _kEmail);
        await _secureStorage.delete(key: _kPassword);
      }
    } catch (e) {
      log('Could not save credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          Icons.security,
                          size: 54.sp,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'TrackLovedOnes',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Always connect with your world',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Email TextFormField
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 15.5.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
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
                      ),
                      SizedBox(height: 18.h),

                      // Password TextFormField
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !isPasswordVisible,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.trim().length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 15.5.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.white60,
                            size: 24.sp,
                          ),
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 44.w,
                              minHeight: 46.h,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white,
                              size: 22.sp,
                            ),
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
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: const Color(0xFFC5A038),
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white70),
                              onChanged: (v) =>
                                  setState(() => rememberMe = v ?? false),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () =>
                                setState(() => rememberMe = !rememberMe),
                            child: Text(
                              "Remember me",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      const ForgotPassWordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
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
                                  try {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    final service = ref.read(
                                      authServiceProvider,
                                    );
                                    final response = await service.loginData(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                    if (response.success == true) {
                                      await _saveOrClearCredentials();
                                      var box = Hive.box("userdata");
                                      await box.put(
                                        "token",
                                        response.data!.token,
                                      );
                                      await box.put(
                                        "id",
                                        response.data!.user!.id,
                                      );
                                      await box.put(
                                        "name",
                                        response.data!.user!.name,
                                      );
                                      await box.put(
                                        "isProfileComplete",
                                        response
                                                .data
                                                ?.user
                                                ?.isProfileComplete ==
                                            true,
                                      );

                                      await box.put(
                                        "email",
                                        response.data!.user!.email,
                                      );
                                      if (context.mounted) {
                                        final isLocationGranted =
                                            await Permission.location.isGranted;
                                        final isContactsGranted =
                                            await Permission.contacts.isGranted;
                                        if (!context.mounted) return;
                                        if (!isLocationGranted ||
                                            !isContactsGranted) {
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
                                        if (response
                                                .data
                                                ?.user
                                                ?.isProfileComplete ==
                                            true) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DynamicDashboardScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        } else {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ProfileScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        }
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
                                  'SIGN IN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.5.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Don't have an account? Sign Up",
                          style: TextStyle(
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'OR',
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                      SizedBox(height: 12.h),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(52.h),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () {
                          
                        },
                        icon: Icon(
                          Icons.g_mobiledata,
                          size: 32.sp,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5.sp,
                          ),
                        ),
                      ),
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
}
