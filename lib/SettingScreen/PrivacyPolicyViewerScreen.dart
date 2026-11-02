import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_loved/LoginScreen/DpdpaTranslations.dart';

class PrivacyPolicyViewerScreen extends StatefulWidget {
  final bool isHindi;
  final int initialTabIndex;

  const PrivacyPolicyViewerScreen({
    super.key,
    this.isHindi = false,
    this.initialTabIndex = 0,
  });

  @override
  State<PrivacyPolicyViewerScreen> createState() =>
      _PrivacyPolicyViewerScreenState();
}

class _PrivacyPolicyViewerScreenState extends State<PrivacyPolicyViewerScreen> {
  late bool _isHindi;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _selectedTab = widget.initialTabIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    const brightGold = Color(0xFFD4AF37);
    final policyData = DpdpaTranslations.languages[_isHindi ? 'hi' : 'en'] ??
        DpdpaTranslations.languages['en']!;

    String contentToShow;
    String badgeLabel;

    switch (_selectedTab) {
      case 1:
        contentToShow = policyData.termsContent ?? policyData.policyContent;
        badgeLabel = _isHindi
            ? 'उपयोग की शर्तें (TERMS OF USE - DPDPA & IT ACT)'
            : 'STATUTORY TERMS OF USE (DPDPA 2023 & IT ACT)';
        break;
      case 2:
        contentToShow =
            policyData.disclaimerContent ?? policyData.policyContent;
        badgeLabel = _isHindi
            ? 'वैधानिक अस्वीकरण (LEGAL DISCLAIMERS & SAFE HARBOR)'
            : 'LEGAL DISCLAIMERS & SAFE HARBOR (IT ACT SEC 79)';
        break;
      case 3:
        contentToShow = policyData.policyContent;
        badgeLabel = _isHindi
            ? 'संपूर्ण कानूनी दस्तावेज (FULL STATUTORY PACKAGE)'
            : 'COMPLETE STATUTORY LEGAL PACKAGE';
        break;
      case 0:
      default:
        // Section 1: Privacy Policy portion or full
        contentToShow = policyData.policyContent.split('============================================================\nSECTION 2').first.trim();
        badgeLabel = _isHindi
            ? 'आधिकारिक DPDP अधिनियम, 2023 गोपनीयता नीति'
            : 'OFFICIAL DPDP ACT, 2023 PRIVACY POLICY';
        break;
    }

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
          _isHindi
              ? 'कानूनी नीतियां एवं शर्तें'
              : 'Privacy Policy & Terms',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Language toggle
          TextButton(
            onPressed: () {
              setState(() {
                _isHindi = !_isHindi;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                border: Border.all(color: brightGold.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(12.r),
                color: brightGold.withValues(alpha: 0.15),
              ),
              child: Text(
                _isHindi ? 'EN' : 'हिंदी',
                style: GoogleFonts.outfit(
                  color: brightGold,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
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
          child: Column(
            children: [
              // Navigation Pills
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabPill(0, _isHindi ? 'गोपनीयता नीति' : 'Privacy Policy'),
                      SizedBox(width: 8.w),
                      _buildTabPill(1, _isHindi ? 'उपयोग की शर्तें' : 'Terms of Use'),
                      SizedBox(width: 8.w),
                      _buildTabPill(2, _isHindi ? 'कानूनी अस्वीकरण' : 'Legal Disclaimer'),
                      SizedBox(width: 8.w),
                      _buildTabPill(3, _isHindi ? 'संपूर्ण दस्तावेज़' : 'Full Document'),
                    ],
                  ),
                ),
              ),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: brightGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: brightGold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          badgeLabel,
                          style: GoogleFonts.outfit(
                            color: brightGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                            letterSpacing: 0.4,
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
                          contentToShow,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13.sp,
                            height: 1.55,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    final isSelected = _selectedTab == index;
    const brightGold = Color(0xFFD4AF37);

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? brightGold : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? brightGold : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? const Color(0xFF0F3D38) : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
