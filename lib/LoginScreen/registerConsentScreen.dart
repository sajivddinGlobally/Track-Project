import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class RegistrationConsentScreen extends StatefulWidget {
  const RegistrationConsentScreen({super.key});

  @override
  State<RegistrationConsentScreen> createState() =>
      _RegistrationConsentScreenState();
}

class _RegistrationConsentScreenState extends State<RegistrationConsentScreen>
    with WidgetsBindingObserver {
  bool _agreedToTerms = false;
  bool _isRequestingPermissions = false;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _disclaimerRecognizer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showPolicyDialog('Terms of Use');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _showPolicyDialog('Data Privacy');
    _disclaimerRecognizer = TapGestureRecognizer()
      ..onTap = () => _showPolicyDialog('Disclaimer');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _disclaimerRecognizer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIfPermissionsNowGranted();
    }
  }

  void _showPolicyDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Colors.white24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Here are the details regarding our $title. We ensure complete security, end-to-end encryption, and full compliance for protecting your loved ones and your private data.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.5.sp,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePermissionsAndConsent() async {
    if (!_agreedToTerms) {
      showErrorSnackBar(
        "Please agree to the Terms of Use & Privacy Policy to continue.",
      );
      return;
    }

    setState(() {
      _isRequestingPermissions = true;
    });

    try {
      // Trigger native OS permission dialogs for mandatory permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.contacts,
        Permission.notification,
      ].request();

      final isLocationGranted =
          statuses[Permission.location]?.isGranted ?? false;
      final isContactsGranted =
          statuses[Permission.contacts]?.isGranted ?? false;
      final isLocationPermanentlyDenied =
          statuses[Permission.location]?.isPermanentlyDenied ?? false;
      final isContactsPermanentlyDenied =
          statuses[Permission.contacts]?.isPermanentlyDenied ?? false;

      if (isLocationGranted && isContactsGranted) {
        if (mounted) {
          showSuccessSnackBar(
            "All mandatory permissions granted successfully.",
          );
          _navigateToNextScreen();
        }
      } else if (isLocationPermanentlyDenied || isContactsPermanentlyDenied) {
        if (mounted) {
          _showSettingsDialog();
        }
      } else {
        if (mounted) {
          _showPermissionRequiredDialog();
        }
      }
    } catch (e) {
      log("Error while requesting permissions: $e");
      if (mounted) {
        showErrorSnackBar(
          "An error occurred while requesting permissions. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermissions = false;
        });
      }
    }
  }

  Future<void> _checkIfPermissionsNowGranted() async {
    final locationStatus = await Permission.location.status;
    final contactsStatus = await Permission.contacts.status;

    if (locationStatus.isGranted && contactsStatus.isGranted) {
      if (mounted) {
        showSuccessSnackBar("All mandatory permissions verified successfully.");
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    var box = Hive.box("userdata");
    var token = box.get("token");
    var isProfileComplete = box.get("isProfileComplete");

    if (token != null) {
      if (isProfileComplete == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DynamicDashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (route) => false,
        );
      }
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFD4AF37),
              size: 26.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Permission Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Location and Contacts permissions are mandatory for real-time family tracking and emergency safety alerts. You have disabled them. Please enable them in your device settings to continue.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF072420),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.security, color: const Color(0xFFD4AF37), size: 26.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Mandatory Permissions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Track Loved requires Location and Contacts permissions to function. You must allow these permissions to proceed with registration.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss',
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF072420),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _handlePermissionsAndConsent();
            },
            child: Text(
              'Grant Permissions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Badge
                    Container(
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 54.sp,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // App Title & Tagline
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
                      'Registration Consent & Permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'The app requires the following permissions to protect and connect with your loved ones. Please review and agree before proceeding.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Permission Items List
                    _buildConsentCard(
                      icon: Icons.contacts_outlined,
                      title: 'Contacts Sharing',
                      description:
                          'Allow access to contacts for easy loved-one pairing and instant emergency alerts.',
                    ),
                    SizedBox(height: 14.h),

                    _buildConsentCard(
                      icon: Icons.location_on_outlined,
                      title: 'Precise Location',
                      description:
                          'Enable real-time live location sharing to track and locate your family circle.',
                    ),
                    SizedBox(height: 14.h),

                    _buildConsentCard(
                      icon: Icons.notifications_none_outlined,
                      title: 'Alerts & Notifications',
                      description:
                          'Receive instant alerts and updates for family safety and network connections.',
                    ),
                    SizedBox(height: 22.h),

                    // Agreement Checkbox & Links
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            activeColor: const Color(0xFFD4AF37),
                            checkColor: const Color(0xFF072420),
                            side: const BorderSide(color: Colors.white60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _agreedToTerms = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'I agree to the services and have read the ',
                                    ),
                                    TextSpan(
                                      text: 'Terms of Use',
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: _termsRecognizer,
                                    ),
                                    const TextSpan(text: ', '),
                                    TextSpan(
                                      text: 'Data Privacy',
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: _privacyRecognizer,
                                    ),
                                    const TextSpan(text: ', and '),
                                    TextSpan(
                                      text: 'Disclaimer',
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: _disclaimerRecognizer,
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Primary Submit Button matching LoginScreen
                    Container(
                      width: double.infinity,
                      height: 54.h,
                      decoration: BoxDecoration(
                        gradient: _agreedToTerms
                            ? const LinearGradient(
                                colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                              )
                            : null,
                        color: _agreedToTerms
                            ? null
                            : Colors.white.withValues(alpha: 0.12),
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
                        onPressed: (_agreedToTerms && !_isRequestingPermissions)
                            ? _handlePermissionsAndConsent
                            : null,
                        child: _isRequestingPermissions
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
                                'SUBMIT & AGREE',
                                style: TextStyle(
                                  color: _agreedToTerms
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13.5.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
