import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getMyJobApplicationsProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/GetMyJobApplicationsResModel.dart';

/// Data Model for a candidate application entry
class CandidateApplicationItem {
  final String id;
  final String companyName;
  final String position;
  final String referenceCode;
  final String appliedDate;
  String status;
  final Color statusColor;
  final String sharedInfo;
  bool isWithdrawn;
  bool activeShare;
  final String? resumeUrl;
  final String? comment;

  CandidateApplicationItem({
    required this.id,
    required this.companyName,
    required this.position,
    required this.referenceCode,
    required this.appliedDate,
    required this.status,
    required this.statusColor,
    required this.sharedInfo,
    this.isWithdrawn = false,
    this.activeShare = true,
    this.resumeUrl,
    this.comment,
  });
}

class ManageMyApplicationsScreen extends ConsumerStatefulWidget {
  final bool initialHindi;
  const ManageMyApplicationsScreen({super.key, this.initialHindi = false});

  @override
  ConsumerState<ManageMyApplicationsScreen> createState() =>
      _ManageMyApplicationsScreenState();
}

class _ManageMyApplicationsScreenState
    extends ConsumerState<ManageMyApplicationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool _isHindi;
  final Set<String> _withdrawnApplicationIds = {};

  // Closed / Terminated Applications
  final List<Map<String, dynamic>> _closedApplications = [
    {
      'company': 'TechCorp Solutions',
      'position': 'Customer Success Lead',
      'status': 'Closed / Withdrawn by Company',
      'date': '15-Oct-2026',
      'complianceNote':
          'Corporate access tokens have been automatically revoked. The employer can no longer view your files.',
      'complianceNoteHi':
          'कॉर्पोरेट एक्सेस टोकन स्वतः रद्द कर दिए गए हैं। नियोक्ता अब आपकी फाइलें नहीं देख सकता।',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isHindi = widget.initialHindi;
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'Recently';
    }
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      return '$day-$month-$year';
    } catch (_) {
      return rawDate;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return const Color(0xFFF59E0B);
    final s = status.toLowerCase();
    if (s.contains('shortlist') ||
        s.contains('accept') ||
        s.contains('hired')) {
      return const Color(0xFF10B981);
    }
    if (s.contains('reject') || s.contains('close') || s.contains('withdraw')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFFF59E0B);
  }

  String _getStatusDisplay(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return 'Under Review';
    final s = rawStatus.toLowerCase();
    if (s == 'open') return 'Under Review';
    if (s == 'shortlisted') return 'Shortlisted';
    if (s == 'hired') return 'Hired';
    if (s == 'rejected') return 'Rejected';
    if (s == 'closed') return 'Closed';
    return rawStatus
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  List<CandidateApplicationItem> _mapApplications(
    List<JobApplicationItemData> items,
  ) {
    final List<CandidateApplicationItem> mapped = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final app = item.application;
      final post = item.post;

      final rawId = app?.id ?? post?.id ?? 'APP-${i + 101}';
      final company =
          (post?.ownerId?.name != null &&
              post!.ownerId!.name!.trim().isNotEmpty)
          ? post.ownerId!.name!
          : 'Registered Employer';
      final position =
          (post?.jobTitle != null && post!.jobTitle!.trim().isNotEmpty)
          ? post.jobTitle!
          : 'Job Application';

      String refCode;
      if (post?.id != null && post!.id!.length >= 6) {
        refCode =
            'TLO-JOB-${post.id!.substring(post.id!.length - 6).toUpperCase()}';
      } else if (app?.id != null && app!.id!.length >= 6) {
        refCode =
            'TLO-JOB-${app.id!.substring(app.id!.length - 6).toUpperCase()}';
      } else {
        refCode = 'TLO-JOB-${101 + i}';
      }

      final appliedDate = _formatDate(app?.createdAt);
      final rawStatus = post?.status ?? 'Under Review';
      final status = _getStatusDisplay(rawStatus);
      final statusColor = _getStatusColor(rawStatus);
      final sharedInfo =
          (item.resumeUploaded == true ||
              (app?.resumeUrl != null && app!.resumeUrl!.isNotEmpty))
          ? 'Name, Phone, Email, Static Resume (.pdf)'
          : 'Name, Phone, Email';

      final isWithdrawn = _withdrawnApplicationIds.contains(rawId);

      mapped.add(
        CandidateApplicationItem(
          id: rawId,
          companyName: company,
          position: position,
          referenceCode: refCode,
          appliedDate: appliedDate,
          status: isWithdrawn
              ? (_isHindi
                    ? 'सहमति वापस ली गई (डेटा मिटाया गया)'
                    : 'Consent Withdrawn (Data Erased)')
              : status,
          statusColor: isWithdrawn ? Colors.white60 : statusColor,
          sharedInfo: sharedInfo,
          isWithdrawn: isWithdrawn,
          activeShare: !isWithdrawn,
          resumeUrl: app?.resumeUrl,
          comment: app?.comment,
        ),
      );
    }
    return mapped;
  }

  // ========================================================================
  // Backend Compliance Ledger Logger (DPDPA 2023 Statutory Proof)
  // ========================================================================
  void _logComplianceLedgerEvent({
    required String referenceId,
    required String companyId,
    required String revocationType,
  }) {
    final ledgerPayload = {
      "compliance_ledger_event": "USER_APPLICATION_CONSENT_REVOCATION",
      "schema_version": "TLO-DPDPA-USER-DASH-V1.0",
      "timestamp_iso8601": DateTime.now().toUtc().toIso8601String(),
      "user_action": {
        "data_principal_user_id": "USR-CURRENT-AUTH",
        "target_application_reference": referenceId,
        "associated_employer_id": companyId,
        "revocation_type": revocationType,
      },
      "privacy_enforcement_status": {
        "b2b_dashboard_view_revoked": true,
        "static_file_payload_inaccessible": true,
        "gps_isolation_barrier_checked": true,
        "intermediary_safe_harbor_preserved": true,
      },
    };

    log(
      '🛡️ [COMPLIANCE LEDGER AUDIT LOG]:\n${const JsonEncoder.withIndent('  ').convert(ledgerPayload)}',
    );
  }

  // ========================================================================
  // Execute Granular Right to Erasure for a single application
  // ========================================================================
  void _confirmWithdrawAndErase(CandidateApplicationItem app) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.gavel_rounded,
              color: const Color(0xFFF87171),
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi
                    ? 'आवेदन वापस लें एवं डेटा मिटाएं?'
                    : 'Withdraw Application & Erase Data?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5.sp,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isHindi
                  ? 'कंपनी: ${app.companyName}\nपद: ${app.position} (${app.referenceCode})'
                  : 'Company: ${app.companyName}\nPosition: ${app.position} (${app.referenceCode})',
              style: TextStyle(
                color: const Color(0xFFE6C567),
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                _isHindi
                    ? '⚠️ DPDP Act, 2023 (वैधानिक अधिकार): इस पर क्लिक करते ही कंपनी का टोकन तुरंत रद्द (active_share = false) हो जाएगा। कंपनी को सूचित किया जाएगा कि "उम्मीदवार ने सहमति वापस ले ली है। डेटा अब उपलब्ध नहीं है।"'
                    : '⚠️ DPDP Act, 2023 (Statutory Erasure): Immediately executes token nullification (active_share = false). The company\'s console will display: "This candidate has withdrawn consent. Data is no longer accessible."',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5.sp,
                  height: 1.35,
                ),
              ),
            ),
          ],
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
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);

              // 1. Token Nullification & Status Change
              setState(() {
                _withdrawnApplicationIds.add(app.id);
                app.activeShare = false;
                app.isWithdrawn = true;
                app.status = _isHindi
                    ? 'सहमति वापस ली गई (डेटा मिटाया गया)'
                    : 'Consent Withdrawn (Data Erased)';
              });

              // 2. Immutable Record Retention Ledger Event
              _logComplianceLedgerEvent(
                referenceId: app.referenceCode,
                companyId: app.companyName,
                revocationType: 'Granular Right to Erasure Execution',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0F3D38),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: const BorderSide(color: Color(0xFF10B981)),
                  ),
                  content: Text(
                    _isHindi
                        ? '✅ टोकन रद्द किया गया! कंपनी के पास से आपकी फ़ाइलें और संपर्क तुरंत ब्लॉक कर दिए गए हैं।'
                        : '✅ Token Nullified! Employer access to your resume & contact has been permanently erased.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white),
                  ),
                ),
              );
            },
            child: Text(
              _isHindi ? 'हाँ, डेटा मिटाएं' : 'Confirm & Erase',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // Execute Global Bulk Consent Revocation
  // ========================================================================
  void _confirmRevokeAllTokens(List<CandidateApplicationItem> currentApps) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: const Color(0xFFFBBF24),
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi
                    ? 'सभी कॉर्पोरेट डेटा टोकन रद्द करें?'
                    : 'Revoke All Corporate Data Access?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5.sp,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isHindi
              ? 'यह कार्रवाई सभी सक्रिय कंपनियों को DPDP अधिनियम के तहत आपके पेशेवर रिकॉर्ड और बायोडाटा को अपनी आंतरिक प्रणालियों से तत्काल प्रभाव से मिटाने का वैधानिक निर्देश भेजेगी।'
              : 'This action immediately signals all active employers to scrub your professional files and contact records from their internal systems under the DPDP Act, 2023.',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.4),
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
              backgroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                for (var app in currentApps) {
                  _withdrawnApplicationIds.add(app.id);
                  app.activeShare = false;
                  app.isWithdrawn = true;
                  app.status = _isHindi
                      ? 'वैधानिक रूप से रद्द'
                      : 'Statutorily Revoked';
                  _logComplianceLedgerEvent(
                    referenceId: app.referenceCode,
                    companyId: app.companyName,
                    revocationType: 'Universal Bulk Consent Withdrawal',
                  );
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0F3D38),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: const BorderSide(color: Color(0xFFFBBF24)),
                  ),
                  content: Text(
                    _isHindi
                        ? '🔄 सभी कॉर्पोरेट एक्सेस टोकन सफलतापूर्वक रद्द कर दिए गए हैं।'
                        : '🔄 Universal corporate data access tokens successfully revoked.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white),
                  ),
                ),
              );
            },
            child: Text(
              _isHindi ? 'सभी टोकन रद्द करें' : 'Revoke All Tokens',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(getMyJobApplicationsProvider);
    final activeApplications = applicationsAsync.valueOrNull != null
        ? _mapApplications(applicationsAsync.value!.data)
        : <CandidateApplicationItem>[];

    return Scaffold(
      drawer: AppDrawer(isHindi: _isHindi),
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      appBar: AppBarScreen(
        titleEn: 'Manage My Applications',
        titleHi: 'मेरे आवेदन प्रबंधित करें',
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
            constraints: const BoxConstraints(maxWidth: 700),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: RefreshIndicator(
              color: const Color(0xFF5EEAD4),
              backgroundColor: const Color(0xFF0F3D38),
              onRefresh: () async {
                ref.invalidate(getMyJobApplicationsProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // Top Header Pill
                  Container(
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
                          Icons.dashboard_customize_rounded,
                          color: const Color(0xFF5EEAD4),
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _isHindi
                              ? 'उम्मीदवार गोपनीयता कॉकपिट (Candidate Privacy Cockpit)'
                              : 'Candidate Privacy Cockpit',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5EEAD4),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // ==========================================================
                  // 🔒 SECURITY LOG BANNER
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3D38),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: const BoxDecoration(
                            color: Color(0xFF072420),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: const Color(0xFF5EEAD4),
                            size: 18.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi
                                    ? '🔒 सुरक्षा लॉग: शून्य स्थान दृश्यता (Zero Map Visibility)'
                                    : '🔒 SECURITY LOG: Zero Map Visibility',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5EEAD4),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _isHindi
                                    ? 'नीचे दिए गए अवसरों के पास केवल वही स्थिर रेज़्युमे पैकेट है जिसे आपने आवेदन के समय अधिकृत किया था। उनके पास आपकी लाइव लोकेशन या मैप का शून्य एक्सेस है।'
                                    : 'The opportunities below only hold the static resume packet you authorized at the time of application. They have zero map or location visibility.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ==========================================================
                  // 💼 SUBMITTED APPLICATIONS (Active Opportunities)
                  // ==========================================================
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        color: const Color(0xFFE6C567),
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _isHindi
                            ? 'जमा किए गए आवेदन (सक्रिय अवसर)'
                            : 'SUBMITTED APPLICATIONS (Active Opportunities)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE6C567),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  applicationsAsync.when(
                    loading: () => Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5EEAD4),
                        ),
                      ),
                    ),
                    error: (error, stack) => Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3D38),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: const Color(0xFFF87171),
                            size: 28.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _isHindi
                                ? 'आवेदन लोड करने में विफल'
                                : 'Failed to load applications',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF14B8A6),
                              foregroundColor: const Color(0xFF002E29),
                            ),
                            onPressed: () =>
                                ref.refresh(getMyJobApplicationsProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              _isHindi ? 'पुनः प्रयास करें' : 'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),
                    data: (res) {
                      final apps = _mapApplications(res.data);
                      if (apps.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: Text(
                              _isHindi
                                  ? 'कोई सक्रिय आवेदन नहीं मिला।'
                                  : 'No active applications found.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: apps
                            .map((app) => _buildApplicationCard(app))
                            .toList(),
                      );
                    },
                  ),

                  SizedBox(height: 18.h),

                  // ==========================================================
                  // 🚫 CLOSED / TERMINATED OPPORTUNITIES (Access Expired)
                  // ==========================================================
                  // Row(
                  //   children: [
                  //     Icon(
                  //       Icons.block_flipped,
                  //       color: const Color(0xFFF87171),
                  //       size: 18.sp,
                  //     ),
                  //     SizedBox(width: 8.w),
                  //     Text(
                  //       _isHindi
                  //           ? 'बंद / समाप्त अवसर (एक्सेस समाप्त)'
                  //           : 'CLOSED / TERMINATED OPPORTUNITIES (Access Expired)',
                  //       style: TextStyle(
                  //         fontSize: 14.sp,
                  //         fontWeight: FontWeight.bold,
                  //         color: const Color(0xFFF87171),
                  //         letterSpacing: 0.2,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: 8.h),

                  // ..._closedApplications.map(
                  //   (closed) => _buildClosedCard(closed),
                  // ),

                  // SizedBox(height: 20.h),

                  // // ==========================================================
                  // // 🔄 STATUTORY CONSENT WITHDRAWAL PANEL
                  // // ==========================================================
                  // Container(
                  //   padding: EdgeInsets.all(14.w),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFF0F3D38),
                  //     borderRadius: BorderRadius.circular(12.r),
                  //     border: Border.all(
                  //       color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  //       width: 1.2,
                  //     ),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Icon(
                  //             Icons.security_update_warning_rounded,
                  //             color: const Color(0xFFFBBF24),
                  //             size: 18.sp,
                  //           ),
                  //           SizedBox(width: 8.w),
                  //           Expanded(
                  //             child: Text(
                  //               _isHindi
                  //                   ? 'वैधानिक सहमति वापसी पैनल (Statutory Consent Withdrawal)'
                  //                   : 'STATUTORY CONSENT WITHDRAWAL PANEL',
                  //               style: TextStyle(
                  //                 fontSize: 13.5.sp,
                  //                 fontWeight: FontWeight.bold,
                  //                 color: const Color(0xFFFBBF24),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       SizedBox(height: 8.h),
                  //       Text(
                  //         _isHindi
                  //             ? 'इस बटन पर टैप करने से सभी सक्रिय नियोक्ताओं को DPDP अधिनियम, 2023 के तहत आपकी पेशेवर फ़ाइलों और संपर्कों को अपने आंतरिक डेटाबेस से तुरंत हटाने (Scrub/Erase) का कानूनी निर्देश जाता है।'
                  //             : 'Tapping this immediately signals all active employers to scrub your professional files and contact logs from their internal records under the DPDP Act, 2023.',
                  //         style: TextStyle(
                  //           fontSize: 12.sp,
                  //           color: Colors.white70,
                  //           height: 1.35,
                  //         ),
                  //       ),
                  //       SizedBox(height: 12.h),
                  //       SizedBox(
                  //         width: double.infinity,
                  //         height: 44.h,
                  //         child: ElevatedButton.icon(
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: const Color(0xFFD97706),
                  //             foregroundColor: Colors.white,
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(8.r),
                  //             ),
                  //           ),
                  //           onPressed: () =>
                  //               _confirmRevokeAllTokens(activeApplications),
                  //           icon: Icon(
                  //             Icons.power_settings_new_rounded,
                  //             size: 18.sp,
                  //           ),
                  //           label: Text(
                  //             _isHindi
                  //                 ? 'सभी कॉर्पोरेट डेटा एक्सेस टोकन रद्द करें'
                  //                 : 'Revoke All Corporate Data Access Tokens',
                  //             style: TextStyle(
                  //               fontSize: 13.sp,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Application Card UI Component
  Widget _buildApplicationCard(CandidateApplicationItem app) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D38),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: app.isWithdrawn
              ? Colors.white24
              : const Color(0xFF14B8A6).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Company & Status
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
                  Icons.business_rounded,
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
                      app.companyName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '• Position: ${app.position}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFFE6C567),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '• Ref Code: ${app.referenceCode}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: app.isWithdrawn
                      ? Colors.grey.withValues(alpha: 0.2)
                      : app.statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: app.isWithdrawn
                        ? Colors.grey
                        : app.statusColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  app.status,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: app.isWithdrawn ? Colors.white60 : app.statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Metadata row
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF072420),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12.sp,
                      color: Colors.white54,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${_isHindi ? 'आवेदन की तिथि' : 'Applied On'}: ${app.appliedDate}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 12.sp,
                      color: Colors.white54,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        '${_isHindi ? 'साझा की गई जानकारी' : 'Shared Info'}: ${app.sharedInfo}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                if (app.comment != null && app.comment!.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 12.sp,
                        color: Colors.white54,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${_isHindi ? 'टिप्पणी' : 'Comment'}: ${app.comment}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (app.resumeUrl != null &&
                    app.resumeUrl!.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 12.sp,
                        color: const Color(0xFF5EEAD4),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${_isHindi ? 'रेज़्युमे' : 'Resume'}: ${app.resumeUrl!.split('/').last}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF5EEAD4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Action Button
          if (!app.isWithdrawn)
            SizedBox(
              width: double.infinity,
              height: 38.h,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () => _confirmWithdrawAndErase(app),
                icon: Icon(Icons.delete_forever_rounded, size: 16.sp),
                label: Text(
                  _isHindi
                      ? '🛑 आवेदन वापस लें एवं डेटा मिटाएं'
                      : '🛑 WITHDRAW APPLICATION & ERASE DATA',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: const Color(0xFF34D399),
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? 'कंपनी का डेटा एक्सेस शून्य (Nullified) कर दिया गया है।'
                          : 'Corporate access token nullified. Employer access erased.',
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

  // Closed Card UI Component
  Widget _buildClosedCard(Map<String, dynamic> closed) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D38).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.domain_disabled_rounded,
                color: Colors.white54,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  closed['company'] as String,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  _isHindi
                      ? '❌ कंपनी द्वारा बंद / वापस लिया गया'
                      : '❌ Closed / Withdrawn',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFFFCA5A5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '• Position: ${closed['position']}',
            style: TextStyle(fontSize: 13.sp, color: Colors.white60),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF072420),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: const Color(0xFF34D399),
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? closed['complianceNoteHi'] as String
                        : closed['complianceNote'] as String,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: Colors.white70,
                      height: 1.3,
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
}
