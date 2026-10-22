import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:track_loved/LoginScreen/DpdpaTranslations.dart';

class DpdpaConsentResult {
  final bool agreed;
  final String languageCode;
  final bool consentLocationAndProfile;
  final bool consentMarketplace;
  final bool consentContacts;
  final bool parentalDeclaration;

  const DpdpaConsentResult({
    required this.agreed,
    required this.languageCode,
    required this.consentLocationAndProfile,
    required this.consentMarketplace,
    required this.consentContacts,
    required this.parentalDeclaration,
  });
}

class DpdpaPolicyDialog extends StatefulWidget {
  final String initialLanguageCode;
  final bool initialLocationConsent;
  final bool initialMarketplaceConsent;
  final bool initialContactsConsent;
  final bool initialParentalConsent;

  const DpdpaPolicyDialog({
    super.key,
    this.initialLanguageCode = 'en',
    this.initialLocationConsent = false,
    this.initialMarketplaceConsent = false,
    this.initialContactsConsent = false,
    this.initialParentalConsent = false,
  });

  @override
  State<DpdpaPolicyDialog> createState() => _DpdpaPolicyDialogState();
}

class _DpdpaPolicyDialogState extends State<DpdpaPolicyDialog> {
  late String _selectedLanguageCode;
  late bool _consentLocationAndProfile;
  late bool _consentMarketplace;
  late bool _consentContacts;
  late bool _parentalDeclaration;

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = widget.initialLanguageCode;
    _consentLocationAndProfile = widget.initialLocationConsent;
    _consentMarketplace = widget.initialMarketplaceConsent;
    _consentContacts = widget.initialContactsConsent;
    _parentalDeclaration = widget.initialParentalConsent;
  }

  final List<DropdownMenuItem<String>> _menuItems = const [
    DropdownMenuItem(value: 'en', child: Text('English')),
    DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
    DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
    DropdownMenuItem(value: 'ne', child: Text('नेपाली (Nepali)')),
    DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
    DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
    DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
    DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)')),
    DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
    DropdownMenuItem(value: 'ml', child: Text('മലയാളം (Malayalam)')),
    DropdownMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ (Punjabi)')),
    DropdownMenuItem(value: 'or', child: Text('ଓଡ଼ିଆ (Odia)')),
    DropdownMenuItem(value: 'ur', child: Text('اردو (Urdu)')),
    DropdownMenuItem(value: 'as', child: Text('অসমীয়া (Assamese)')),
    DropdownMenuItem(value: 'ma', child: Text('मैथिली (Maithili)')),
    DropdownMenuItem(value: 'sa', child: Text('संस्कृतम् (Sanskrit)')),
    DropdownMenuItem(value: 'sat', child: Text('ᱥᱟᱱᱛᱟᱲᱤ (Santali)')),
    DropdownMenuItem(value: 'ks', child: Text('کٲশُر (Kashmiri)')),
    DropdownMenuItem(value: 'sd', child: Text('सिन्धी (Sindhi)')),
    DropdownMenuItem(value: 'ko', child: Text('कोंकणी (Konkani)')),
    DropdownMenuItem(value: 'mni', child: Text('মণিপুরী (Manipuri)')),
    DropdownMenuItem(value: 'brx', child: Text('बोडो (Bodo)')),
    DropdownMenuItem(value: 'doi', child: Text('डोगरी (Dogri)')),
  ];

  @override
  Widget build(BuildContext context) {
    final langData = DpdpaTranslations.get(_selectedLanguageCode);

    final String currentTitle = langData.title;
    final String currentSubtitle = langData.subtitle;
    final String currentBtn = langData.buttonText;
    final String chkLocText = langData.chkLocation;
    final String chkMarketText = langData.chkMarketplace;
    final String chkContactText = langData.chkContacts;
    final String chkParentText = langData.chkParent;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 540.w, maxHeight: 720.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F3D38), Color(0xFF0A2E2A), Color(0xFF051C19)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title and Close Button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: const Color(0xFFD4AF37),
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            currentSubtitle,
                            style: TextStyle(
                              color: const Color(0xFF00E676),
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 22.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Language Selector Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                color: Colors.white.withValues(alpha: 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: const Color(0xFFD4AF37),
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Language / भाषा:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF072420),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguageCode,
                          dropdownColor: const Color(0xFF0A2E2A),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: const Color(0xFFD4AF37),
                            size: 20.sp,
                          ),
                          isDense: true,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguageCode = newValue;
                              });
                            }
                          },
                          items: _menuItems,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Policy Content Scroll View
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: RawScrollbar(
                    thumbColor: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    radius: Radius.circular(6.r),
                    thickness: 4.w,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(right: 8.w),
                      child: Text(
                        langData.policyContent,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Consent Checkboxes
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mandatory Consent
                    Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      decoration: BoxDecoration(
                        color: _consentLocationAndProfile
                            ? const Color(0xFF00E676).withValues(alpha: 0.08)
                            : Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _consentLocationAndProfile
                              ? const Color(0xFF00E676).withValues(alpha: 0.4)
                              : Colors.red.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                        title: Text(
                          chkLocText,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: _consentLocationAndProfile
                                ? Colors.white
                                : const Color(0xFFFFB74D),
                          ),
                        ),
                        value: _consentLocationAndProfile,
                        activeColor: const Color(0xFF00E676),
                        checkColor: Colors.black,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        onChanged: (val) => setState(
                          () => _consentLocationAndProfile = val ?? false,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),

                    // Marketplace Consent
                    _buildCheckboxTile(
                      title: chkMarketText,
                      value: _consentMarketplace,
                      onChanged: (val) =>
                          setState(() => _consentMarketplace = val ?? false),
                    ),

                    // Contacts Consent
                    _buildCheckboxTile(
                      title: chkContactText,
                      value: _consentContacts,
                      onChanged: (val) =>
                          setState(() => _consentContacts = val ?? false),
                    ),

                    // Parental Gate Declaration
                    _buildCheckboxTile(
                      title: chkParentText,
                      value: _parentalDeclaration,
                      isItalic: true,
                      onChanged: (val) =>
                          setState(() => _parentalDeclaration = val ?? false),
                    ),
                  ],
                ),
              ),

              // Bottom Button Row
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _consentLocationAndProfile
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFE6C567),
                                    Color(0xFFC5A038),
                                  ],
                                )
                              : null,
                          color: _consentLocationAndProfile
                              ? null
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: ElevatedButton(
                          onPressed: _consentLocationAndProfile
                              ? () {
                                  Navigator.pop(
                                    context,
                                    DpdpaConsentResult(
                                      agreed: true,
                                      languageCode: _selectedLanguageCode,
                                      consentLocationAndProfile:
                                          _consentLocationAndProfile,
                                      consentMarketplace: _consentMarketplace,
                                      consentContacts: _consentContacts,
                                      parentalDeclaration: _parentalDeclaration,
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledForegroundColor: Colors.white38,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            currentBtn,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              color: _consentLocationAndProfile
                                  ? Colors.black87
                                  : Colors.white38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isItalic = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white70,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        value: value,
        activeColor: const Color(0xFF00E676),
        checkColor: Colors.black,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
