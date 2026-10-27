import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/myCompanyJobPostsProvider.dart';
import 'package:track_loved/DrawerScreen/provider/myBusinessOpportunitiesProvider.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/GetMyCompanyJobPostsResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/GetMyBusinessOpportunitiesResModel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/Data/BodyModel/updateJobPostBodyModel.dart';

/// Model for Employer Job Posting
class EmployerJobItem {
  final String id;
  String title;
  final String referenceCode;
  final String postedDate;
  String status;
  final Color statusColor;
  String locationText;
  int activeApplicants;
  String description;
  String contact;
  bool isPurged;

  EmployerJobItem({
    required this.id,
    required this.title,
    required this.referenceCode,
    required this.postedDate,
    required this.status,
    required this.statusColor,
    required this.locationText,
    required this.activeApplicants,
    required this.description,
    required this.contact,
    this.isPurged = false,
  });
}

/// Model for Business Expansion Posting
class EmployerExpansionItem {
  final String id;
  String title;
  final String referenceCode;
  final String postedDate;
  String status;
  final Color statusColor;
  String targetRegion;
  int investorProposals;
  String parameters;
  String contact;
  bool isPurged;

  EmployerExpansionItem({
    required this.id,
    required this.title,
    required this.referenceCode,
    required this.postedDate,
    required this.status,
    required this.statusColor,
    required this.targetRegion,
    required this.investorProposals,
    required this.parameters,
    required this.contact,
    this.isPurged = false,
  });
}

class ManageMyPostingsScreen extends ConsumerStatefulWidget {
  final bool initialHindi;
  const ManageMyPostingsScreen({super.key, this.initialHindi = false});

  @override
  ConsumerState<ManageMyPostingsScreen> createState() =>
      _ManageMyPostingsScreenState();
}

class _ManageMyPostingsScreenState extends ConsumerState<ManageMyPostingsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  late bool _isHindi;
  final ScrollController _jobsScrollController = ScrollController();
  final ScrollController _expansionsScrollController = ScrollController();
  final Set<String> _purgedExpansions = {};

  @override
  void initState() {
    super.initState();
    _isHindi = widget.initialHindi;
    _tabController = TabController(length: 2, vsync: this);
    _jobsScrollController.addListener(_onJobsScroll);
    _expansionsScrollController.addListener(_onExpansionsScroll);
  }

  void _onJobsScroll() {
    if (_jobsScrollController.hasClients) {
      if (_jobsScrollController.position.pixels >=
          _jobsScrollController.position.maxScrollExtent - 200) {
        ref.read(myCompanyJobPostsProvider.notifier).fetchNextPage();
      }
    }
  }

  void _onExpansionsScroll() {
    if (_expansionsScrollController.hasClients) {
      if (_expansionsScrollController.position.pixels >=
          _expansionsScrollController.position.maxScrollExtent - 200) {
        ref.read(myBusinessOpportunitiesProvider.notifier).fetchNextPage();
      }
    }
  }

  @override
  void dispose() {
    _jobsScrollController.removeListener(_onJobsScroll);
    _jobsScrollController.dispose();
    _expansionsScrollController.removeListener(_onExpansionsScroll);
    _expansionsScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ========================================================================
  // Compliance Verification Ledger Logging (B2B Close Audit Proof)
  // ========================================================================
  void _logJobCloseLedger({
    required String referenceId,
    required int activeApplicants,
  }) {
    final ledgerPayload = {
      "compliance_ledger_event": "JOB_POSTING_LIFECYCLE_CLOSE",
      "schema_version": "TLO-DPDPA-B2B-CLOSE-V1.0",
      "timestamp_iso8601": DateTime.now().toUtc().toIso8601String(),
      "action_context": {
        "employer_entity_id": "EMP-CURRENT-AUTH",
        "job_posting_reference_id": referenceId,
        "requested_lifecycle_state": "PERMANENT_ERASURE_MANDATE",
        "active_applicants_at_closure": activeApplicants,
      },
      "privacy_enforcement_status": {
        "public_feed_visibility_dropped": true,
        "employer_candidate_view_tokens_revoked": true,
        "gps_isolation_intact": true,
        "statutory_erasure_notice_acknowledged": true,
      },
    };

    log(
      '🛡️ [JOB CLOSE COMPLIANCE LEDGER EVENT]:\n${const JsonEncoder.withIndent('  ').convert(ledgerPayload)}',
    );
  }

  void _logExpansionCloseLedger({
    required String referenceId,
    required int activeApplicants,
  }) {
    final ledgerPayload = {
      "compliance_ledger_event": "BUSINESS_EXPANSION_LIFECYCLE_CLOSE",
      "schema_version": "TLO-DPDPA-B2B-EXP-V1.0",
      "timestamp_iso8601": DateTime.now().toUtc().toIso8601String(),
      "action_context": {
        "employer_entity_id": "EMP-CURRENT-AUTH",
        "expansion_posting_reference_id": referenceId,
        "requested_lifecycle_state": "PERMANENT_ERASURE_MANDATE",
        "active_applicants_at_closure": activeApplicants,
      },
      "privacy_enforcement_status": {
        "public_feed_visibility_dropped": true,
        "employer_candidate_view_tokens_revoked": true,
        "gps_isolation_intact": true,
        "statutory_erasure_notice_acknowledged": true,
      },
    };

    log(
      '🛡️ [EXPANSION CLOSE COMPLIANCE LEDGER EVENT]:\n${const JsonEncoder.withIndent('  ').convert(ledgerPayload)}',
    );
  }

  // ========================================================================
  // Option 1: Edit / Modify Posting Requirements (With Compliance Boundary)
  // ========================================================================
  void _showEditJobDialog(MyCompanyJobPostItem job) {
    final titleController = TextEditingController(text: job.jobTitle ?? '');
    final descController = TextEditingController(
      text: job.jobDescription ?? '',
    );
    final contactController = TextEditingController(
      text: job.applicationContactEmail ?? '',
    );
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F3D38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Color(0xFF14B8A6), width: 1.2),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: const Color(0xFF5EEAD4),
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _isHindi
                      ? 'नौकरी की आवश्यकताएं संपादित करें'
                      : 'Edit Job Requirements',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5.sp,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compliance Boundary Banner
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF78350F).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFFBBF24),
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? '⚠️ अनुपालन सीमा: आप विवरण या कौशल संपादित कर सकते हैं। आप किसी भी आवेदक से रीयल-टाइम GPS ट्रैकिंग या स्थान साझा करने की मांग करने के लिए पूर्णतः प्रतिबंधित हैं।'
                              : '⚠️ COMPLIANCE BOUNDARY: You can modify descriptions, skillsets, or contact text. You are strictly PROHIBITED from demanding real-time GPS tracking or location-sharing metrics from applicants.',
                          style: TextStyle(
                            color: const Color(0xFFFDE68A),
                            fontSize: 11.5.sp,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                Text(
                  _isHindi ? 'पद का शीर्षक' : 'Job Title',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5.sp),
                ),
                SizedBox(height: 4.h),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF072420),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                Text(
                  _isHindi ? 'नौकरी विवरण' : 'Description / Requirements',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5.sp),
                ),
                SizedBox(height: 4.h),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF072420),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                Text(
                  _isHindi ? 'कंपनी संपर्क विवरण' : 'Contact Information',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5.sp),
                ),
                SizedBox(height: 4.h),
                TextField(
                  controller: contactController,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF072420),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                _isHindi ? 'रद्द करें' : 'Cancel',
                style: TextStyle(
                  color: isLoading ? Colors.white24 : Colors.white60,
                  fontSize: 13.5.sp,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B4F4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() {
                        isLoading = true;
                      });
                      try {
                        final service = ref.read(authServiceProvider);
                        final res = await service.updateJobPosting(
                          UpdateJobPostingBodyModel(
                            id: job.id,
                            jobTitle: titleController.text.trim(),
                            jobDescription: descController.text.trim(),
                            applicationContactEmail: contactController.text
                                .trim(),
                          ),
                        );
                        if (res.success == true) {
                          ref
                              .read(myCompanyJobPostsProvider.notifier)
                              .refresh();
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0F3D38),
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  _isHindi
                                      ? '✅ नौकरी की आवश्यकताएं सफलतापूर्वक अपडेट कर दी गईं!'
                                      : '✅ Job requirements updated within compliance boundaries.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red.shade800,
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  res.message ??
                                      (_isHindi
                                          ? 'अपडेट करने में विफल!'
                                          : 'Failed to update job post.'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        log(e.toString());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red.shade800,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                _isHindi
                                    ? 'अपडेट करने में त्रुटि हुई!'
                                    : 'An error occurred while updating.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (dialogCtx.mounted) {
                          setDialogState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
              child: isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isHindi ? 'बदलाव सहेजें' : 'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5.sp,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // Option 2: Delete / Unlist Opportunity Permanently (With Cascading Checkboxes)
  // ========================================================================
  void _showDeleteJobDialog(MyCompanyJobPostItem job) {
    bool check1 = false;
    bool check2 = false;
    final applicantsCount = job.applicants?.length ?? job.applicationCount ?? 0;
    final refCode = (job.id != null && job.id!.length >= 6)
        ? 'TLO-JOB-${job.id!.substring(job.id!.length - 6).toUpperCase()}'
        : (job.id ?? 'TLO-JOB');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isReadyToDelete = check1 && check2;

          return AlertDialog(
            backgroundColor: const Color(0xFF0F3D38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.delete_forever_rounded,
                  color: const Color(0xFFF87171),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? 'नौकरी स्थायी रूप से हटाएं?'
                        : 'Permanent Deletion & Data Erasure',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${job.jobTitle ?? ''} ($refCode)',
                    style: TextStyle(
                      color: const Color(0xFFE6C567),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Warning Notice
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _isHindi
                          ? '🚨 अनिवार्य वैधानिक कैस्केडिंग नियम (हटाने पर): स्थायी विलोपन निष्पादित करने के लिए नीचे दिए गए दोनों बॉक्स चेक करना अनिवार्य है:'
                          : '🚨 MANDATORY STATUTORY CASCADING RULES (Upon Deletion): Checking the boxes below is mandatory to execute permanent deletion:',
                      style: TextStyle(
                        color: const Color(0xFFFCA5A5),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Checkbox 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: check1,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) {
                          setModalState(() => check1 = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? '* मैं पुष्टि करता हूँ कि यह अवसर भर चुका है या रद्द कर दिया गया है। मैं समझता हूँ कि इस पोस्ट को हटाने से यह सार्वजनिक नेटवर्क से तुरंत हटा दी जाएगी।'
                              : '* I verify that this opportunity is filled or canceled. I understand that deleting this post will immediately unlist it from the public user network.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Checkbox 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: check2,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) {
                          setModalState(() => check2 = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? '* मैं सहमति देता हूँ कि DPDP अधिनियम, 2023 के तहत हमारी कंपनी अपने आंतरिक डेटाबेस से सभी $applicantsCount आवेदकों के डाउनलोड किए गए या स्थानीय रूप से संग्रहीत बायोडाटा (Resume) और संपर्क विवरण तुरंत मिटा (Shred/Purge) देगी।'
                              : '* I agree to immediately purge, delete, and shred all downloaded or locally stored resume files, contact details, and personal data of the $applicantsCount applicants from our company\'s internal databases, as required by the DPDP Act, 2023.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  _isHindi ? 'रद्द करें' : 'Cancel',
                  style: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReadyToDelete
                      ? const Color(0xFFDC2626)
                      : Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: !isReadyToDelete
                    ? null
                    : () {
                        Navigator.pop(dialogCtx);

                        // 1. Backend Data Cascade State Change
                        setState(() {
                          job.status = 'PURGED';
                        });

                        // 2. Compliance Ledger Log
                        _logJobCloseLedger(
                          referenceId: refCode,
                          activeApplicants: applicantsCount,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0F3D38),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                            ),
                            content: Text(
                              _isHindi
                                  ? '🗑️ पोस्ट हटा दी गई। पब्लिक फीड से हटाई गई और सभी $applicantsCount आवेदकों के डेटा टोकन नष्ट कर दिए गए।'
                                  : '🗑️ Post purged from public feed. Candidate tokens revoked & compliance ledger updated.',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                child: Text(
                  _isHindi ? 'स्थायी रूप से हटाएं' : 'Confirm Deletion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================================================
  // Delete Expansion Posting Flow
  // ========================================================================
  void _showDeleteExpansionDialog(MyBusinessOpportunityItem exp) {
    bool check1 = false;
    bool check2 = false;
    final expTitle =
        exp.opportunityHeadline ??
        exp.opportunityType ??
        (_isHindi ? 'व्यापार विस्तार' : 'Business Expansion');
    final expRefCode = (exp.id != null && exp.id!.length >= 6)
        ? 'TLO-EXP-${exp.id!.substring(exp.id!.length - 6).toUpperCase()}'
        : (exp.id ?? 'TLO-EXP');
    final expProposals = exp.applicants?.length ?? exp.applicationCount ?? 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isReadyToDelete = check1 && check2;

          return AlertDialog(
            backgroundColor: const Color(0xFF0F3D38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.delete_forever_rounded,
                  color: const Color(0xFFF87171),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? 'बिज़नेस एक्सपैंशन पोस्ट हटाएं?'
                        : 'Permanent Erasure & Listing Takedown',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$expTitle ($expRefCode)',
                    style: TextStyle(
                      color: const Color(0xFFE6C567),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _isHindi
                          ? '🚨 अनिवार्य वैधानिक कैस्केडिंग नियम: स्थायी टेकडाउन के लिए दोनों शर्तों की पुष्टि अनिवार्य है:'
                          : '🚨 MANDATORY STATUTORY CASCADING RULES (Upon Deletion): Confirm both conditions for permanent takedown:',
                      style: TextStyle(
                        color: const Color(0xFFFCA5A5),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Checkbox 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: check1,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) {
                          setModalState(() => check1 = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? '* मैं पुष्टि करता हूँ कि यह एक्सपैंशन अवसर बंद/पार्टनरशिप हो चुका है। यह सार्वजनिक नेटवर्क से तुरंत हटा दिया जाएगा।'
                              : '* I verify that this expansion opportunity is closed, partnered, or withdrawn. It will immediately be removed from the public network feed.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Checkbox 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: check2,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) {
                          setModalState(() => check2 = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? '* मैं DPDP अधिनियम, 2023 के तहत उन सभी $expProposals आवेदकों के इन्वेस्टमेंट प्रोफाइल व संपर्कों को अपने सिस्टम से तुरंत नष्ट करने की सहमति देता हूँ।'
                              : '* I agree to immediately delete, purge, and shred all downloaded investment profiles and contacts of the $expProposals applicants from internal storage under the DPDP Act, 2023.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  _isHindi ? 'रद्द करें' : 'Cancel',
                  style: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReadyToDelete
                      ? const Color(0xFFDC2626)
                      : Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: !isReadyToDelete
                    ? null
                    : () {
                        Navigator.pop(dialogCtx);
                        setState(() {
                          if (exp.id != null) {
                            _purgedExpansions.add(exp.id!);
                          }
                        });

                        _logExpansionCloseLedger(
                          referenceId: expRefCode,
                          activeApplicants: expProposals,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0F3D38),
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              _isHindi
                                  ? '🗑️ बिज़नेस एक्सपैंशन पोस्ट सफलतापूर्वक हटा दी गई।'
                                  : '🗑️ Business expansion purged and access tokens revoked.',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                child: Text(
                  _isHindi ? 'स्थायी रूप से हटाएं' : 'Confirm Takedown',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(isHindi: _isHindi),
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      appBar: AppBarScreen(
        titleEn: 'Manage Published Postings',
        titleHi: 'प्रकाशित अवसर प्रबंधित करें',
        isHindi: _isHindi,
        notificationCount: 0,
        onLanguageChanged: (val) {
          setState(() {
            _isHindi = val;
          });
        },
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tagline Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF072420),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: const Color(0xFF5EEAD4),
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          _isHindi
                              ? '🔒 B2B नियोक्ता कंसोल (रीयल-टाइम GPS ट्रैकिंग से पूर्णतः अलग)'
                              : '🔒 B2B Employer Console (Blinded from Real-time Tracking Engine)',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5EEAD4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Tabs for Job Opportunities vs Business Expansions
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3D38),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFE6C567),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFFE6C567),
                    unselectedLabelColor: Colors.white60,
                    labelStyle: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.work_rounded, size: 18),
                        text: _isHindi ? 'नौकरी के अवसर' : 'Job Postings',
                      ),
                      Tab(
                        icon: const Icon(Icons.trending_up_rounded, size: 18),
                        text: _isHindi
                            ? 'बिज़नेस एक्सपैंशन'
                            : 'Business Expansions',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // TabBar View Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: Job Postings
                      _buildJobsTab(),

                      // TAB 2: Business Expansions
                      _buildExpansionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // Tab 1: Manage Published Job Postings
  // ========================================================================
  Widget _buildJobsTab() {
    final jobPostsState = ref.watch(myCompanyJobPostsProvider);

    return RefreshIndicator(
      color: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F3D38),
      onRefresh: () async {
        await ref.read(myCompanyJobPostsProvider.notifier).refresh();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content body based on AsyncValue
          Expanded(
            child: jobPostsState.posts.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF5EEAD4)),
                    SizedBox(height: 12.h),
                    Text(
                      _isHindi
                          ? 'आपकी नौकरियां लोड हो रही हैं...'
                          : 'Loading your job postings...',
                      style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: const Color(0xFFF87171),
                        size: 40.sp,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        _isHindi
                            ? 'डेटा लोड करने में विफल: ${error.toString()}'
                            : 'Failed to load posts: ${error.toString()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                      SizedBox(height: 14.h),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4F4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () => ref
                            .read(myCompanyJobPostsProvider.notifier)
                            .fetchFirstPage(),
                        icon: const Icon(Icons.refresh),
                        label: Text(_isHindi ? 'पुनः प्रयास करें' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_off_outlined,
                            color: Colors.white38,
                            size: 54.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _isHindi
                                ? 'कोई नौकरी पोस्ट नहीं मिली'
                                : 'No Job Postings Found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              _isHindi
                                  ? 'जब आप नई नौकरी पोस्ट करेंगे, तो वह यहाँ दिखाई देगी।'
                                  : 'When you create a job posting, it will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _jobsScrollController,
                  itemCount:
                      jobs.length + (jobPostsState.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == jobs.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF5EEAD4),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _isHindi
                                    ? 'और नौकरियां लोड हो रही हैं...'
                                    : 'Loading more posts...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final job = jobs[index];
                    return _buildDynamicJobCard(job);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicJobCard(MyCompanyJobPostItem job) {
    final isPurged =
        (job.status ?? '').toUpperCase() == 'PURGED' ||
        (job.status ?? '').toUpperCase() == 'CLOSED';
    final isActive =
        (job.status ?? 'active').toLowerCase() == 'active' ||
        (job.status ?? '').toLowerCase() == 'open';

    final statusColor = isPurged
        ? const Color(0xFFEF4444)
        : (isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B));

    final locationParts = [
      job.city,
      job.state,
      job.pincode,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    final locationText = locationParts.isNotEmpty
        ? locationParts
        : (_isHindi ? 'स्थान उपलब्ध नहीं' : 'Location Not Specified');

    final postedDateText = job.createdAt != null
        ? DateFormat('dd-MMM-yyyy').format(job.createdAt!)
        : (_isHindi ? 'हाल ही में' : 'Recently');

    final refCode = (job.id != null && job.id!.length >= 6)
        ? 'TLO-JOB-${job.id!.substring(job.id!.length - 6).toUpperCase()}'
        : (job.id ?? 'TLO-JOB');

    final applicantsList = job.applicants ?? [];
    final applicantsCount = applicantsList.isNotEmpty
        ? applicantsList.length
        : (job.applicationCount ?? 0);

    String? ctcFormatted;
    if (job.annualCtcPackage != null && job.annualCtcPackage! > 0) {
      ctcFormatted =
          '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(job.annualCtcPackage)} / yr';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D38),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPurged
              ? Colors.red.withValues(alpha: 0.4)
              : const Color(0xFF14B8A6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF072420),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.business_center,
                  color: const Color(0xFF5EEAD4),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobTitle ??
                          (_isHindi ? 'शीर्षक रहित' : 'Untitled Role'),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Ref: $refCode | Posted: $postedDateText',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '📍 $locationText',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFFE6C567),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  isPurged
                      ? (_isHindi ? 'हटाया गया' : 'PURGED')
                      : (job.status ?? 'ACTIVE').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Meta tags: Employment type, Hierarchy, CTC
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: [
              if (job.employmentType != null &&
                  job.employmentType!.trim().isNotEmpty)
                _buildTagChip(job.employmentType!),
              if (job.hierarchyLevel != null &&
                  job.hierarchyLevel!.trim().isNotEmpty)
                _buildTagChip(job.hierarchyLevel!),
              if (ctcFormatted != null)
                _buildTagChip(ctcFormatted, isGold: true),
            ],
          ),

          SizedBox(height: 10.h),

          // Applicants count pill (Tappable to view applicant list)
          InkWell(
            onTap: () => _showApplicantsBottomSheet(context, job),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF072420),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: applicantsCount > 0
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.6)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 15.sp,
                    color: const Color(0xFF5EEAD4),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? 'सक्रिय आवेदक: $applicantsCount उम्मीदवार'
                          : 'Active Applicants: $applicantsCount Candidates',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    _isHindi ? 'आवेदक देखें' : 'View Applicants',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFFE6C567),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right,
                    size: 15.sp,
                    color: const Color(0xFFE6C567),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Actions
          if (!isPurged)
            Row(
              children: [
                // Option 1: Edit Requirements
                Expanded(
                  child: SizedBox(
                    height: 38.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5EEAD4),
                        side: const BorderSide(color: Color(0xFF14B8A6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () => _showEditJobDialog(job),
                      icon: Icon(Icons.edit_rounded, size: 15.sp),
                      label: Text(
                        _isHindi
                            ? 'आवश्यकताएं संपादित करें'
                            : 'Edit Requirements',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),

                // Option 2: Delete / Unlist
                Expanded(
                  child: SizedBox(
                    height: 38.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () => _showDeleteJobDialog(job),
                      icon: Icon(Icons.delete_sweep_rounded, size: 15.sp),
                      label: Text(
                        _isHindi ? 'स्थायी डिलीट' : 'Delete / Unlist',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: const Color(0xFFF87171),
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? 'पोस्ट हटा दी गई है। सभी आवेदक टोकन हमेशा के लिए रद्द हो चुके हैं।'
                          : 'Job unlisted & candidate data scrubbed per DPDP Act.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, {bool isGold = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xFFE6C567).withValues(alpha: 0.15)
            : const Color(0xFF14B8A6).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: isGold
              ? const Color(0xFFE6C567).withValues(alpha: 0.4)
              : const Color(0xFF14B8A6).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          color: isGold ? const Color(0xFFE6C567) : const Color(0xFF5EEAD4),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ========================================================================
  // BottomSheet: View Applicants For Selected Job
  // ========================================================================
  void _showApplicantsBottomSheet(
    BuildContext context,
    MyCompanyJobPostItem job,
  ) {
    final applicants = job.applicants ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        height: 0.8.sh,
        decoration: BoxDecoration(
          color: const Color(0xFF0F3D38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: const Color(0xFF14B8A6), width: 1.2),
        ),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 12.h),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: const Color(0xFF5EEAD4),
                    size: 22.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHindi
                              ? 'प्राप्त आवेदन (${applicants.length})'
                              : 'Job Applicants (${applicants.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          job.jobTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFE6C567),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(bCtx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),

            // List of Applicants
            Expanded(
              child: applicants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            color: Colors.white38,
                            size: 48.sp,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            _isHindi
                                ? 'इस नौकरी के लिए कोई आवेदक नहीं है'
                                : 'No applicants yet for this job',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.5.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(16.w),
                      itemCount: applicants.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (ctx, idx) {
                        final applicant = applicants[idx];
                        return _buildApplicantCard(applicant);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(JobApplicantItem applicant) {
    final appliedAtText = applicant.appliedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(applicant.appliedAt!)
        : null;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF072420),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFF0F3D38),
                child: Text(
                  (applicant.name != null && applicant.name!.isNotEmpty)
                      ? applicant.name![0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name ??
                          (_isHindi ? 'अनाम उम्मीदवार' : 'Anonymous Candidate'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (appliedAtText != null)
                      Text(
                        '${_isHindi ? 'आवेदन तिथि' : 'Applied'}: $appliedAtText',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Contact Details
          if (applicant.email != null && applicant.email!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14.sp,
                  color: const Color(0xFFE6C567),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    applicant.email!,
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          if (applicant.phone != null && applicant.phone!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 14.sp,
                  color: const Color(0xFFE6C567),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    applicant.phone!,
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],

          // Comment
          if (applicant.comment != null &&
              applicant.comment!.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3D38),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '💬 "${applicant.comment!.trim()}"',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Resume button
          if (applicant.resumeUrl != null &&
              applicant.resumeUrl!.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5EEAD4),
                  side: const BorderSide(color: Color(0xFF14B8A6)),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(Icons.description_outlined, size: 14.sp),
                label: Text(
                  _isHindi ? 'बायोडाटा / Resume देखें' : 'View Resume',
                  style: TextStyle(fontSize: 11.5.sp),
                ),
                onPressed: () async {
                  try {
                    final uri = Uri.parse(applicant.resumeUrl!.trim());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isHindi
                                  ? 'बायोडाटा लिंक नहीं खुल सका'
                                  : 'Could not open resume URL',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    log('Error launching resume: $e');
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================================
  // Tab 2: Manage Business Expansions
  // ========================================================================
  Widget _buildExpansionsTab() {
    final expansionsState = ref.watch(myBusinessOpportunitiesProvider);

    return RefreshIndicator(
      color: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F3D38),
      onRefresh: () async {
        await ref.read(myBusinessOpportunitiesProvider.notifier).refresh();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: expansionsState.opportunities.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF5EEAD4)),
                    SizedBox(height: 12.h),
                    Text(
                      _isHindi
                          ? 'आपके बिज़नेस एक्सपैंशन लोड हो रहे हैं...'
                          : 'Loading your business opportunities...',
                      style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: const Color(0xFFF87171),
                        size: 40.sp,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        _isHindi
                            ? 'डेटा लोड करने में विफल: ${error.toString()}'
                            : 'Failed to load opportunities: ${error.toString()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                      SizedBox(height: 14.h),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4F4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () => ref
                            .read(myBusinessOpportunitiesProvider.notifier)
                            .fetchFirstPage(),
                        icon: const Icon(Icons.refresh),
                        label: Text(_isHindi ? 'पुनः प्रयास करें' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (expansions) {
                if (expansions.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            color: Colors.white38,
                            size: 54.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _isHindi
                                ? 'कोई बिज़नेस एक्सपैंशन नहीं मिला'
                                : 'No Business Opportunities Found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              _isHindi
                                  ? 'जब आप नया बिज़नेस एक्सपैंशन पोस्ट करेंगे, तो वह यहाँ दिखाई देगा।'
                                  : 'When you create a business opportunity, it will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _expansionsScrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount:
                      expansions.length +
                      (expansionsState.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == expansions.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5EEAD4),
                          ),
                        ),
                      );
                    }

                    final exp = expansions[index];
                    return _buildExpansionCard(exp);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionCard(MyBusinessOpportunityItem exp) {
    final isPurged =
        _purgedExpansions.contains(exp.id) ||
        (exp.status?.toLowerCase() == 'purged' ||
            exp.status?.toLowerCase() == 'closed');
    final title =
        exp.opportunityHeadline ??
        exp.opportunityType ??
        (_isHindi ? 'व्यापार विस्तार' : 'Business Expansion');
    final refCode = (exp.id != null && exp.id!.length >= 6)
        ? 'TLO-EXP-${exp.id!.substring(exp.id!.length - 6).toUpperCase()}'
        : (exp.id ?? 'TLO-EXP');
    final postedDate = exp.createdAt != null
        ? DateFormat('dd-MMM-yyyy').format(exp.createdAt!)
        : '-';
    final targetRegion = [
      if (exp.city != null && exp.city!.isNotEmpty) exp.city,
      if (exp.state != null && exp.state!.isNotEmpty) exp.state,
      if (exp.pincode != null && exp.pincode!.isNotEmpty) exp.pincode,
    ].join(', ');
    final proposalsCount = exp.applicants?.length ?? exp.applicationCount ?? 0;
    final statusText = isPurged
        ? (_isHindi ? 'हटाया गया (Purged)' : 'PURGED & DATA SHREDDED')
        : (exp.status?.toUpperCase() ?? 'OPEN');
    final statusColor = isPurged
        ? Colors.red
        : (exp.status?.toLowerCase() == 'open'
              ? const Color(0xFF10B981)
              : const Color(0xFFE6C567));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D38),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPurged
              ? Colors.red.withValues(alpha: 0.4)
              : const Color(0xFF14B8A6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF072420),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: const Color(0xFF5EEAD4),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Ref: $refCode | Posted: $postedDate',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                    ),
                    if (targetRegion.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '📍 Target: $targetRegion',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFE6C567),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isPurged
                      ? Colors.red.withValues(alpha: 0.2)
                      : statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isPurged ? Colors.red : statusColor,
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isPurged ? const Color(0xFFFCA5A5) : statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Proposals count pill (Tappable to view applicant list)
          InkWell(
            onTap: proposalsCount > 0
                ? () => _showExpansionApplicantsBottomSheet(context, exp)
                : null,
            borderRadius: BorderRadius.circular(6.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF072420),
                borderRadius: BorderRadius.circular(6.r),
                border: proposalsCount > 0
                    ? Border.all(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.how_to_reg_rounded,
                    size: 14.sp,
                    color: proposalsCount > 0
                        ? const Color(0xFF5EEAD4)
                        : Colors.white38,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? 'प्राप्त निवेशक प्रस्ताव: $proposalsCount आवेदक'
                          : 'Received Investor Proposals: $proposalsCount Applicants',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: proposalsCount > 0
                            ? Colors.white
                            : Colors.white60,
                      ),
                    ),
                  ),
                  if (proposalsCount > 0) ...[
                    Text(
                      _isHindi ? 'आवेदक देखें' : 'View Applicants',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF5EEAD4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10.sp,
                      color: const Color(0xFF5EEAD4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Actions
          if (!isPurged)
            Row(
              children: [
                // Option 1: Edit Proposal Parameters
                Expanded(
                  child: SizedBox(
                    height: 38.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5EEAD4),
                        side: const BorderSide(color: Color(0xFF14B8A6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0F3D38),
                            content: Text(
                              _isHindi
                                  ? 'वित्तीय मापदंड संपादित किए जा सकते हैं (GPS ट्रैकिंग प्रतिबंधित)।'
                                  : 'Proposal parameters editable (Continuous GPS tracking prohibited).',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.tune_rounded, size: 15.sp),
                      label: Text(
                        _isHindi ? 'मापदंड संपादित करें' : 'Edit Parameters',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),

                // Option 2: Delete Expansion
                Expanded(
                  child: SizedBox(
                    height: 38.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () => _showDeleteExpansionDialog(exp),
                      icon: Icon(Icons.delete_forever_rounded, size: 15.sp),
                      label: Text(
                        _isHindi ? 'स्थायी टेकडाउन' : 'Permanent Takedown',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: const Color(0xFFF87171),
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? 'एक्सपैंशन टेकडाउन पूर्ण। निवेशक डेटा टोकन नष्ट कर दिए गए।'
                          : 'Expansion listing taken down. Investor tokens purged.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========================================================================
  // BottomSheet: View Applicants For Selected Business Opportunity
  // ========================================================================
  void _showExpansionApplicantsBottomSheet(
    BuildContext context,
    MyBusinessOpportunityItem exp,
  ) {
    final applicants = exp.applicants ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        height: 0.8.sh,
        decoration: BoxDecoration(
          color: const Color(0xFF0F3D38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: const Color(0xFF14B8A6), width: 1.2),
        ),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 12.h),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Icon(
                    Icons.how_to_reg_rounded,
                    color: const Color(0xFF5EEAD4),
                    size: 22.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHindi
                              ? 'प्राप्त निवेशक प्रस्ताव (${applicants.length})'
                              : 'Investor Proposals (${applicants.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          exp.opportunityHeadline ??
                              exp.opportunityType ??
                              'Business Opportunity',
                          style: TextStyle(
                            color: const Color(0xFFE6C567),
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(bCtx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF14B8A6), thickness: 0.8),

            // List of Applicants
            Expanded(
              child: applicants.isEmpty
                  ? Center(
                      child: Text(
                        _isHindi
                            ? 'इस अवसर के लिए अभी तक कोई प्रस्ताव नहीं आया है'
                            : 'No investor proposals yet for this opportunity',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.5.sp,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: applicants.length,
                      itemBuilder: (context, idx) {
                        final applicant = applicants[idx];
                        return _buildOpportunityApplicantCard(applicant);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportunityApplicantCard(OpportunityApplicantItem applicant) {
    final appliedAtText = applicant.appliedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(applicant.appliedAt!)
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF072420),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFF0B4F4A),
                child: Text(
                  (applicant.name != null && applicant.name!.isNotEmpty)
                      ? applicant.name![0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name ??
                          (_isHindi ? 'अनाम आवेदक' : 'Anonymous Applicant'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (appliedAtText != null)
                      Text(
                        'Applied: $appliedAtText',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (applicant.email != null && applicant.email!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 13.sp,
                  color: const Color(0xFF5EEAD4),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    applicant.email!,
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          if (applicant.phone != null && applicant.phone!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 13.sp,
                  color: const Color(0xFF5EEAD4),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    applicant.phone!,
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          if (applicant.comment != null &&
              applicant.comment!.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              '💬 "${applicant.comment!.trim()}"',
              style: TextStyle(
                color: const Color(0xFFFDE68A),
                fontStyle: FontStyle.italic,
                fontSize: 12.sp,
              ),
            ),
          ],
          if (applicant.resumeUrl != null &&
              applicant.resumeUrl!.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(applicant.resumeUrl!.trim());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 14.sp,
                    color: const Color(0xFF5EEAD4),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _isHindi
                        ? 'दस्तावेज़ / प्रोफ़ाइल देखें'
                        : 'View Profile / Document',
                    style: TextStyle(
                      color: const Color(0xFF5EEAD4),
                      fontSize: 12.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
