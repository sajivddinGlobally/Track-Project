import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_loved/LoginScreen/DpdpaTranslations.dart';

class PrivacyPolicyViewerScreen extends StatelessWidget {
  final bool isHindi;

  const PrivacyPolicyViewerScreen({super.key, this.isHindi = false});

  @override
  Widget build(BuildContext context) {
    const brightGold = Color(0xFFD4AF37);
    final policyData = DpdpaTranslations.languages[isHindi ? 'hi' : 'en'] ??
        DpdpaTranslations.languages['en']!;

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
          isHindi ? 'गोपनीयता नीति (DPDPA, 2023)' : 'Privacy Policy (DPDPA 2023)',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 17.sp,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: brightGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: brightGold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    isHindi ? 'आधिकारिक DPDP अधिनियम, 2023 सूचना' : 'Official DPDP Act, 2023 Notice',
                    style: GoogleFonts.outfit(
                      color: brightGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    policyData.policyContent,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12.5.sp,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
