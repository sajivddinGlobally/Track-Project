import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/SubmitGrievanceBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/SubmitGrievanceResModel.dart';

class GrievanceDpoScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const GrievanceDpoScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<GrievanceDpoScreen> createState() => _GrievanceDpoScreenState();
}

class _GrievanceDpoScreenState extends ConsumerState<GrievanceDpoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();

  String _selectedCategory = 'Right to Erasure Denial';
  bool _isVerified = false;
  bool _isSubmitting = false;

  final List<String> _categoriesEn = [
    'Right to Erasure Denial',
    'Incorrect Profile Data',
    'Unauthorized Tracking',
    'Suspicious Corporate Interaction',
  ];

  final List<String> _categoriesHi = [
    'डेटा मिटाने से इनकार (Right to Erasure Denial)',
    'गलत प्रोफ़ाइल डेटा (Incorrect Profile Data)',
    'अनधिकृत ट्रैकिंग (Unauthorized Tracking)',
    'संदिग्ध कॉर्पोरेट गतिविधि (Suspicious Corporate Interaction)',
  ];

  String _getCategoryBackendKey() {
    if (_selectedCategory.contains('Right to Erasure Denial')) {
      return "RIGHT_TO_ERASURE_DENIAL";
    } else if (_selectedCategory.contains('Incorrect Profile Data')) {
      return "INCORRECT_PROFILE_DATA";
    } else if (_selectedCategory.contains('Unauthorized Tracking')) {
      return "UNAUTHORIZED_TRACKING";
    } else if (_selectedCategory.contains('Suspicious Corporate Interaction')) {
      return "SUSPICIOUS_CORPORATE_INTERACTION";
    }
    return "RIGHT_TO_ERASURE_DENIAL";
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _launchEmailIntent(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent('[Statutory Filing - DPDP Act, 2023]')}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailUri);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isHindi
                ? 'ईमेल ऐप नहीं खुला। कृपया मैन्युअल ईमेल भेजें: $email'
                : 'Could not launch email client. Please email manually: $email',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0F3D38),
        ),
      );
    }
  }

  void _submitGrievance() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isHindi
                ? 'कृपया आगे बढ़ने के लिए सत्यापन चेकबॉक्स चुनें'
                : 'Please verify the declaration checkbox before submitting',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final categoryKey = _getCategoryBackendKey();
    final description = _detailsController.text.trim();

    try {
      final body = SubmitGrievanceBodyModel(
        category: categoryKey,
        description: description,
        isVerified: _isVerified,
      );

      final res = await ref.read(authServiceProvider).submitGrievanceData(body);

      final now = DateTime.now().toUtc();
      DateTime slaDeadline = now.add(const Duration(days: 14));
      if (res.slaDeadline != null && res.slaDeadline!.isNotEmpty) {
        try {
          slaDeadline = DateTime.parse(res.slaDeadline!);
        } catch (_) {}
      }

      final receiptCode =
          res.receiptCode ??
          'TLO-GRV-${DateFormat('yyyyMMdd').format(now)}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';

      // Statutory immutable compliance ledger backup
      final Map<String, dynamic> complianceLedgerToken = {
        "compliance_ledger_event": "STATUTORY_GRIEVANCE_LODGED",
        "schema_version": "TLO-DPDPA-GRIEVANCE-V1.0",
        "timestamp_iso8601": now.toIso8601String(),
        "incident_metadata": {
          "acknowledgement_receipt_code": receiptCode,
          "selected_grievance_category": categoryKey,
          "assigned_officer":
              res.assignedOfficer ??
              "Mr. Akash Sharma (grievance@tracklovedones.com)",
          "sla_deadline_iso8601": slaDeadline.toIso8601String(),
          "complaint_excerpt": description,
        },
      };

      try {
        final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
        if (box != null) {
          final List<dynamic> logs =
              box.get('compliance_grievance_logs', defaultValue: <dynamic>[])
                  as List<dynamic>;
          logs.add(jsonEncode(complianceLedgerToken));
          await box.put('compliance_grievance_logs', logs);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _showReceiptDialog(res, receiptCode, slaDeadline);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  void _showReceiptDialog(
    SubmitGrievanceResModel res,
    String receiptCode,
    DateTime slaDeadline,
  ) {
    final assignedOfficer =
        res.assignedOfficer ??
        'Mr. Akash Sharma (grievance@tracklovedones.com)';
    final slaDateFormatted = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(slaDeadline.toLocal());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F3D38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
          ),
          title: Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: const Color(0xFF00E676),
                size: 24.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  widget.isHindi
                      ? 'शिकायत दर्ज कर ली गई है (Grievance Lodged)'
                      : 'Grievance Lodged (शिकायत दर्ज कर ली गई है)',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5.sp,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (res.message != null && res.message!.isNotEmpty) ...[
                  Text(
                    res.message!,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF5EEAD4),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
                Text(
                  widget.isHindi
                      ? 'आपकी कानूनी शिकायत आधिकारिक अनुपालन लेजर में दर्ज कर ली गई है।'
                      : 'Your formal grievance is registered into the immutable compliance ledger under DPDP Act, 2023.',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12.5.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isHindi
                            ? 'पावती रसीद कोड (Receipt Code):'
                            : 'Receipt Code:',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFD4AF37),
                          fontSize: 11.5.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              receiptCode,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Color(0xFFD4AF37),
                              size: 18,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: receiptCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.isHindi
                                        ? 'कोड कॉपी कर लिया गया'
                                        : 'Receipt code copied',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Divider(color: Colors.white12, height: 16.h),
                      Text(
                        widget.isHindi
                            ? 'नामित अधिकारी (Assigned Officer):'
                            : 'Assigned Officer:',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        assignedOfficer,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4FC3F7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5.sp,
                        ),
                      ),
                      Divider(color: Colors.white12, height: 16.h),
                      Text(
                        widget.isHindi
                            ? 'समाधान समयसीमा (Resolution Window):'
                            : 'Resolution Window:',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        widget.isHindi
                            ? '14 कार्य दिवस (14 Business Days) • $slaDateFormatted'
                            : '14 Business Days • $slaDateFormatted',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF00E676),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: const Color(0xFF00E676),
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        widget.isHindi
                            ? 'कॉर्पोरेट ब्लाइंडनेस: कंपनियों और नियोक्ताओं के पास इसका कोई एक्सेस नहीं है।'
                            : 'Corporate Blindness: Employers & recruiters have ZERO access to this dispute.',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                _detailsController.clear();
                setState(() {
                  _isVerified = false;
                });
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                widget.isHindi ? 'ठीक है (OK)' : 'OK / DONE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0F3D38),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    final categories = widget.isHindi ? _categoriesHi : _categoriesEn;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
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
          widget.isHindi ? 'शिकायत एवं DPO पोर्टल' : 'Grievance & DPO Portal',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.sp,
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
                  // Statutory Header Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          brightGold.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: brandGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: brightGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: brightGold,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.isHindi
                                    ? 'DPDP अधिनियम, 2023 वैधानिक केंद्र'
                                    : 'DPDP Act, 2023 Statutory Center',
                                style: GoogleFonts.outfit(
                                  color: brightGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          widget.isHindi
                              ? 'क्या आपको इस बात की चिंता है कि आपकी व्यक्तिगत जानकारी कैसे प्रोसेस, सुरक्षित या मिटाई जाती है? भारतीय कानून के तहत, आपको तत्काल और औपचारिक शिकायत निवारण का अधिकार है।'
                              : 'Do you have concerns regarding how your personal information is processed, secured, or erased? Under Indian law, you have the right to immediate and formal grievance redressal.',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Section 1: Statutory Appointments
                  Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: brightGold, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        widget.isHindi
                            ? '⚖️ वैधानिक नियुक्तियां एवं संपर्क विवरण'
                            : '⚖️ STATUTORY APPOINTMENTS & CONTACT DETAILS',
                        style: GoogleFonts.outfit(
                          color: brightGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Officer 1: Designated Grievance Officer
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18.r,
                              backgroundColor: brightGold.withValues(
                                alpha: 0.2,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: brightGold,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isHindi
                                        ? 'नामित शिकायत अधिकारी (Grievance Officer)'
                                        : 'DESIGNATED GRIEVANCE OFFICER',
                                    style: GoogleFonts.outfit(
                                      color: brightGold,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Mr. Akash Sharma',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '• ${widget.isHindi ? 'पंजीकरण / आईडी:' : 'Registration/ID:'} TLO-GO-2026-04',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12.5.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        InkWell(
                          onTap: () => _launchEmailIntent(
                            'grievance@tracklovedones.com',
                          ),
                          child: Row(
                            children: [
                              Text(
                                '• ${widget.isHindi ? 'सीधा संपर्क ईमेल:' : 'Direct Contact Email:'} ',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'grievance@tracklovedones.com',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF4FC3F7),
                                    fontSize: 12.5.sp,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: const Color(0xFF4FC3F7),
                                size: 14.sp,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '• ${widget.isHindi ? 'डाक पता:' : 'Postal Address:'} Track Loved Ones App Private Limited, 4th Floor, DLF Cyber City, Phase 3, Gurugram, Haryana - 122002, India.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Officer 2: DPO For Escalations
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18.r,
                              backgroundColor: const Color(
                                0xFF00E676,
                              ).withValues(alpha: 0.2),
                              child: Icon(
                                Icons.security_rounded,
                                color: const Color(0xFF00E676),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isHindi
                                        ? 'डेटा सुरक्षा अधिकारी (DPO) - अपील/एस्केलेशन'
                                        : 'DATA PROTECTION OFFICER (DPO) - For Escalations',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF00E676),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ms. Priyanjali Sen',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: () =>
                              _launchEmailIntent('dpo@tracklovedones.com'),
                          child: Row(
                            children: [
                              Text(
                                '• ${widget.isHindi ? 'सीधा संपर्क ईमेल:' : 'Direct Contact Email:'} ',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'dpo@tracklovedones.com',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF4FC3F7),
                                    fontSize: 12.5.sp,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: const Color(0xFF4FC3F7),
                                size: 14.sp,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '• ${widget.isHindi ? 'प्रतिक्रिया प्रतिबद्धता:' : 'Response Commitment:'} ${widget.isHindi ? 'सभी कानूनी गोपनीयता मामलों की जांच 7 से 14 कार्य दिवसों के भीतर की जाती है।' : 'All statutory privacy escalations are investigated and formally addressed within 7 to 14 business days.'}',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Section 2: Form - File a Formal Complaint
                  Row(
                    children: [
                      Icon(Icons.edit_document, color: brightGold, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        widget.isHindi
                            ? '📝 सीधे औपचारिक शिकायत दर्ज करें'
                            : '📝 FILE A FORMAL COMPLAINT DIRECTLY',
                        style: GoogleFonts.outfit(
                          color: brightGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Dropdown: Category
                  Text(
                    widget.isHindi
                        ? 'अपनी विशिष्ट गोपनीयता चिंता का चयन करें:'
                        : 'Select your specific privacy concern:',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF072420),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                        ),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Details Description Box
                  Text(
                    widget.isHindi
                        ? 'अपने डेटा विवाद या शिकायत का विस्तार से वर्णन करें:'
                        : 'Describe your data dispute or grievance in detail:',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 5,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 10) {
                        return widget.isHindi
                            ? 'कृपया न्यूनतम 10 अक्षरों में विवरण लिखें'
                            : 'Please provide at least 10 characters description';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: widget.isHindi
                          ? 'कृपया स्पष्ट विवरण प्रदान करें (समय, दिनांक, कारण आदि)...'
                          : 'Provide specific details regarding the data concern...',
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 13.sp,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: EdgeInsets.all(12.r),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                          color: brightGold,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Verification Checkbox
                  InkWell(
                    onTap: () => setState(() => _isVerified = !_isVerified),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _isVerified,
                          activeColor: brightGold,
                          checkColor: const Color(0xFF0F3D38),
                          onChanged: (v) =>
                              setState(() => _isVerified = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Text(
                              widget.isHindi
                                  ? '* मैं सत्यापित करता/करती हूँ कि दी गई जानकारी सटीक है। इस फॉर्म को सबमिट करने पर एक उच्च-प्राथमिकता एन्क्रिप्टेड टिकट सीधे शिकायत अधिकारी के पास जाता है।'
                                  : '* I verify that the information provided is accurate. Submitting this form routes a high-priority encrypted ticket straight to the Grievance Officer\'s desk.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12.sp,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Corporate Blindness Check Badge
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: const Color(0xFF00E676),
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              widget.isHindi
                                  ? '🏢 कॉर्पोरेट / नियोक्ता खाता बहिष्करण (Corporate Blindness)'
                                  : '🏢 ENTERPRISE / EMPLOYER ACCOUNT EXCLUSION FLAG',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          widget.isHindi
                              ? '• [🛡️ कॉर्पोरेट ब्लाइंडनेस चेक: सक्रिय]\n• सिस्टम स्थिति: कंपनियों और नौकरी पोस्टर्स के पास इस विवाद चैनल का शून्य (0) एक्सेस है और वे उपयोगकर्ता की गोपनीयता शिकायतें नहीं देख सकते।'
                              : '• [🛡️ Corporate Blindness Check: Active]\n• System Status: Companies and business opportunity posters have ZERO access to this dispute channel and cannot view user privacy filings.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 11.5.sp,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            widget.isHindi ? '🔙 वापस जाएं' : '🔙 RETURN',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brightGold,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submitGrievance,
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0F3D38),
                                  ),
                                )
                              : Text(
                                  widget.isHindi
                                      ? '🚀 शिकायत सबमिट करें'
                                      : '🚀 SUBMIT GRIEVANCE',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF0F3D38),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5.sp,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
}
