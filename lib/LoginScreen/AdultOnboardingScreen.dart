import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/DpdpaPolicyDialog.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/UpdateConsentsBodyModel.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class AdultOnboardingScreen extends ConsumerStatefulWidget {
  const AdultOnboardingScreen({super.key});

  @override
  ConsumerState<AdultOnboardingScreen> createState() =>
      _AdultOnboardingScreenState();
}

class _AdultOnboardingScreenState extends ConsumerState<AdultOnboardingScreen> {
  bool _agreedToAdultTerms = false;
  bool _shareLocationWithParent = false;
  bool _isLoading = false;

  Future<void> _openPrivacyPolicyDialog() async {
    final result = await showDialog<DpdpaConsentResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DpdpaPolicyDialog(
        initialLanguageCode: 'en',
        initialLocationConsent: true,
        initialMarketplaceConsent: false,
        initialContactsConsent: false,
        initialParentalConsent: false,
      ),
    );

    if (result != null && result.agreed) {
      setState(() {
        _agreedToAdultTerms = true;
      });
    }
  }

  Future<void> _submitAdultConsent() async {
    if (!_agreedToAdultTerms) {
      showErrorSnackBar(
        'Please agree to the Adult Terms & Privacy Policy to proceed.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // 1. Update consents on backend (realTimeLocation as per toggle)
      try {
        await authService.updateConsentsData(
          UpdateConsentsBodyModel(
            realTimeLocation: _shareLocationWithParent,
            jobMarketplace: false,
            analytics: true,
          ),
        );
      } catch (apiErr) {
        log('[AdultOnboarding] Consent update API warning: $apiErr');
      }

      // 2. Update local Hive state to clear age-out gate
      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');

      await box.put('requiresAdultReconsent', false);
      await box.put('role', 'user');

      if (!mounted) return;

      showSuccessSnackBar(
        'Congratulations! Your adult profile is activated with full data control.',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DynamicDashboardScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      log('[AdultOnboarding] Error submitting adult consent: $e');
      if (mounted) {
        showErrorSnackBar('Failed to activate adult profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Age-out gate is blocking: user must give adult re-consent
      child: Scaffold(
        backgroundColor: const Color(0xFF002E29),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002E29), Color(0xFF001B18)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 10.h),

                  // Celebration Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A038).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFC5A038).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: const Color(0xFFE6C567),
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'DPDPA 2023 • LEGAL GRADUATION',
                          style: TextStyle(
                            color: const Color(0xFFE6C567),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Cake & Shield Icon Stack
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC5A038).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '🎂',
                        style: TextStyle(fontSize: 46.sp),
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // Main Title
                  Text(
                    'Welcome to Adulthood! 🎂',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Hinglish & Legal Notice
                  Text(
                    'Aap 18 saal ke ho gaye hain. Privacy kanoon (DPDPA 2023) ke mutabik aapka account ab aapke poore control mein hai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Info Card explaining rights
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: const Color(0xFF00E676),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'What Changes Today?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        _buildInfoBullet(
                          'Full Sovereign Ownership:',
                          'Your location data is now private by default and cannot be monitored without your explicit adult consent.',
                        ),
                        SizedBox(height: 8.h),
                        _buildInfoBullet(
                          'Direct Legal Rights:',
                          'You can manage your consents, update data, or withdraw permissions anytime in Settings.',
                        ),
                        SizedBox(height: 8.h),
                        _buildInfoBullet(
                          'Parental Gate Unlocked:',
                          'Parental OTP verification is no longer required for your account.',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Action 2: Continue sharing location with parent (Optional Toggle)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: _shareLocationWithParent
                            ? const Color(0xFF00E676).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: _shareLocationWithParent
                                ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: _shareLocationWithParent
                                ? const Color(0xFF00E676)
                                : Colors.white60,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share location with Parent?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _shareLocationWithParent
                                    ? 'Parent can continue tracking your live GPS.'
                                    : 'Parent tracking is stopped. Private by default.',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _shareLocationWithParent,
                          activeTrackColor: const Color(0xFF00E676),
                          onChanged: (val) {
                            setState(() {
                              _shareLocationWithParent = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Action 1: Mandatory Terms & Privacy Checkbox
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: _agreedToAdultTerms
                            ? const Color(0xFF00E676).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreedToAdultTerms,
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
                              _openPrivacyPolicyDialog();
                            } else {
                              setState(() {
                                _agreedToAdultTerms = false;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openPrivacyPolicyDialog,
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Adult Terms of Use',
                                    style: TextStyle(
                                      color: const Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  const TextSpan(text: ' & '),
                                  TextSpan(
                                    text: 'Privacy Policy (DPDPA 2023)',
                                    style: TextStyle(
                                      color: const Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
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
                          tooltip: 'Read Full Policy',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _openPrivacyPolicyDialog,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _agreedToAdultTerms
                            ? [
                                const Color(0xFFE6C567),
                                const Color(0xFFC5A038),
                              ]
                            : [
                                Colors.grey.shade600,
                                Colors.grey.shade700,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: _agreedToAdultTerms
                          ? [
                              BoxShadow(
                                color: const Color(0xFFC5A038)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitAdultConsent,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Activate Adult Profile & Continue',
                                  style: TextStyle(
                                    color: _agreedToAdultTerms
                                        ? Colors.black87
                                        : Colors.white70,
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _agreedToAdultTerms
                                      ? Colors.black87
                                      : Colors.white70,
                                  size: 18.sp,
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
      ),
    );
  }

  Widget _buildInfoBullet(String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Icon(
            Icons.check_circle_outline,
            size: 14.sp,
            color: const Color(0xFF00E676),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$title ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              children: [
                TextSpan(
                  text: body,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                    fontSize: 11.5.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

