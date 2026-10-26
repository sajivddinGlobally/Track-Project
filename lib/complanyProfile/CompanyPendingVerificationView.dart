import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getBussinessProfileProvider.dart';
import 'package:track_loved/complanyProfile/companyProfileScreen.dart';
import 'package:track_loved/core/Data/ResponseModel/getBusinnesProfileModel.dart';

class CompanyPendingVerificationView extends ConsumerWidget {
  final Datum datum;
  final String status;
  final bool isHindi;
  final String screenTitleEn;
  final String screenTitleHi;
  final ValueChanged<bool>? onLanguageChanged;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CompanyPendingVerificationView({
    super.key,
    required this.datum,
    required this.status,
    required this.isHindi,
    required this.screenTitleEn,
    required this.screenTitleHi,
    this.onLanguageChanged,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRejected = status.toLowerCase().trim() == 'rejected';

    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D38),
      key: scaffoldKey,
      drawer: AppDrawer(isHindi: isHindi),
      appBar: AppBarScreen(
        titleEn: screenTitleEn,
        titleHi: screenTitleHi,
        isHindi: isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          if (onLanguageChanged != null) {
            onLanguageChanged!(value);
          }
        },
        onNotificationPressed: () {},
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
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Badge Icon
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? Colors.redAccent.withValues(alpha: 0.12)
                            : brightGold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRejected ? Colors.redAccent : brightGold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isRejected
                                ? Colors.redAccent.withValues(alpha: 0.25)
                                : brightGold.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isRejected
                            ? Icons.error_outline_rounded
                            : Icons.hourglass_top_rounded,
                        size: 50.sp,
                        color: isRejected ? Colors.redAccent : brightGold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Status Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? Colors.redAccent.withValues(alpha: 0.18)
                            : brandGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isRejected ? Colors.redAccent : brandGold,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRejected
                                ? Icons.cancel_outlined
                                : Icons.pending_actions_rounded,
                            size: 16.sp,
                            color: isRejected ? Colors.redAccent : brightGold,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            isRejected
                                ? (isHindi
                                      ? 'सत्यापन अस्वीकृत'
                                      : 'VERIFICATION REJECTED')
                                : (isHindi
                                      ? 'सत्यापन प्रक्रियाधीन'
                                      : 'UNDER ADMIN REVIEW'),
                            style: GoogleFonts.outfit(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isRejected ? Colors.redAccent : brightGold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Title
                    Text(
                      isRejected
                          ? (isHindi
                                ? 'कंपनी प्रोफ़ाइल अस्वीकृत'
                                : 'Company Verification Rejected')
                          : (isHindi
                                ? 'कंपनी प्रोफ़ाइल समीक्षाधीन है'
                                : 'Company Profile Under Review'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Subtitle / Notice
                    Text(
                      isRejected
                          ? (datum.rejectionReason?.isNotEmpty == true
                                ? datum.rejectionReason!
                                : (isHindi
                                      ? 'आपकी कंपनी का विवरण अस्वीकृत कर दिया गया है। कृपया जानकारी सुधार कर पुनः सबमिट करें।'
                                      : 'Your company KYC submission was rejected. Please review the details below and update your submission.'))
                          : (datum.adminMessage?.isNotEmpty == true
                                ? datum.adminMessage!
                                : (isHindi
                                      ? 'आपकी कंपनी प्रोफ़ाइल और KYC विवरण सबमिट हो चुके हैं। एडमिन द्वारा अनुमोदन (Approval) के बाद आप अवसर पोस्ट कर सकेंगे।'
                                      : 'Your company profile & KYC details have been submitted. Once approved by our compliance admin, opportunity postings will be fully unlocked.')),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5.sp,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 22.h),

                    // Submitted Data Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business_center_rounded,
                                    color: brightGold,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isHindi
                                        ? 'प्रस्तुत कंपनी जानकारी'
                                        : 'Submitted Company Information',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: brightGold,
                                    ),
                                  ),
                                ],
                              ),
                              // if (datum.companyId != null || datum.id != null)
                              //   Container(
                              //     padding: EdgeInsets.symmetric(
                              //       horizontal: 8.w,
                              //       vertical: 3.h,
                              //     ),
                              //     decoration: BoxDecoration(
                              //       color: brightGold.withValues(alpha: 0.12),
                              //       borderRadius: BorderRadius.circular(6.r),
                              //       border: Border.all(
                              //         color: brightGold.withValues(alpha: 0.35),
                              //         width: 0.8,
                              //       ),
                              //     ),
                              //     child: Text(
                              //       'ID: ${(datum.companyId ?? datum.id ?? '').substring(0, (datum.companyId ?? datum.id ?? '').length > 8 ? 8 : (datum.companyId ?? datum.id ?? '').length)}',
                              //       style: GoogleFonts.outfit(
                              //         fontSize: 11.sp,
                              //         fontWeight: FontWeight.w600,
                              //         color: brightGold,
                              //       ),
                              //     ),
                              //   ),
                            ],
                          ),
                          if (datum.adminMessage?.isNotEmpty == true ||
                              datum.rejectionReason?.isNotEmpty == true) ...[
                            SizedBox(height: 12.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: isRejected
                                    ? Colors.redAccent.withValues(alpha: 0.1)
                                    : brandGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: isRejected
                                      ? Colors.redAccent
                                      : brandGold,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isRejected
                                        ? Icons.warning_amber_rounded
                                        : Icons.info_outline_rounded,
                                    color: isRejected
                                        ? Colors.redAccent
                                        : brightGold,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      (isRejected
                                              ? datum.rejectionReason
                                              : datum.adminMessage) ??
                                          '',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 12.h),
                          const Divider(height: 1, color: Colors.white12),
                          SizedBox(height: 12.h),

                          // Company Name
                          _buildDetailRow(
                            icon: Icons.domain,
                            label: isHindi ? 'कंपनी का नाम' : 'Company Name',
                            value: datum.registeredCompanyName ?? 'N/A',
                          ),
                          SizedBox(height: 10.h),

                          // Entity Type
                          _buildDetailRow(
                            icon: Icons.apartment,
                            label: isHindi ? 'संस्था का प्रकार' : 'Entity Type',
                            value: datum.companyType ?? 'N/A',
                          ),

                          // Company Official Email
                          if (datum.companyEmail?.isNotEmpty == true ||
                              datum.ownerContact?.email?.isNotEmpty ==
                                  true) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.email_outlined,
                              label: isHindi ? 'कंपनी ईमेल' : 'Company Email',
                              value:
                                  datum.companyEmail ??
                                  datum.ownerContact?.email ??
                                  'N/A',
                              // trailingBadge: Container(
                              //   padding: EdgeInsets.symmetric(
                              //     horizontal: 6.w,
                              //     vertical: 2.h,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color: (datum.companyEmailVerified == true)
                              //         ? const Color(
                              //             0xFF00E676,
                              //           ).withValues(alpha: 0.15)
                              //         : Colors.amber.withValues(alpha: 0.15),
                              //     borderRadius: BorderRadius.circular(4.r),
                              //     border: Border.all(
                              //       color: (datum.companyEmailVerified == true)
                              //           ? const Color(0xFF00E676)
                              //           : Colors.amber,
                              //       width: 0.8,
                              //     ),
                              //   ),
                              //   child: Text(
                              //     (datum.companyEmailVerified == true)
                              //         ? (isHindi ? 'सत्यापित' : 'Verified')
                              //         : (isHindi ? 'लंबित' : 'Pending'),
                              //     style: GoogleFonts.outfit(
                              //       fontSize: 9.5.sp,
                              //       fontWeight: FontWeight.w600,
                              //       color: (datum.companyEmailVerified == true)
                              //           ? const Color(0xFF00E676)
                              //           : Colors.amber,
                              //     ),
                              //   ),
                              // ),
                            ),
                          ],

                          // Company Official Phone
                          if (datum.companyPhoneNumber?.isNotEmpty == true ||
                              datum.ownerContact?.phone?.isNotEmpty ==
                                  true) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.phone_outlined,
                              label: isHindi ? 'कंपनी संपर्क' : 'Company Phone',
                              value:
                                  datum.companyPhoneNumber ??
                                  datum.ownerContact?.phone ??
                                  'N/A',
                            ),
                          ],
                          SizedBox(height: 10.h),

                          // GST Number
                          _buildDetailRow(
                            icon: Icons.verified_outlined,
                            label: isHindi ? 'जीएसटी नंबर' : 'GST Number',
                            value: datum.gstNumber ?? 'N/A',
                          ),
                          SizedBox(height: 10.h),

                          // Company PAN
                          _buildDetailRow(
                            icon: Icons.badge_outlined,
                            label: isHindi ? 'कंपनी पैन' : 'Company PAN',
                            value: datum.companyPanNumber ?? 'N/A',
                          ),
                          SizedBox(height: 10.h),

                          // Address
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: isHindi
                                ? 'पंजीकृत पता'
                                : 'Corporate Address',
                            value: datum.registeredCorporateAddress ?? 'N/A',
                          ),

                          // City, State & PIN
                          if (datum.city?.isNotEmpty == true ||
                              datum.state?.isNotEmpty == true ||
                              datum.pincode?.isNotEmpty == true) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.map_outlined,
                              label: isHindi
                                  ? 'शहर, राज्य व पिन'
                                  : 'City, State & PIN',
                              value: [
                                if (datum.city?.isNotEmpty == true) datum.city!,
                                if (datum.state?.isNotEmpty == true)
                                  datum.state!,
                                if (datum.pincode?.isNotEmpty == true)
                                  '- ${datum.pincode!}',
                              ].join(' '),
                            ),
                          ],

                          if (datum.officialWebsite?.isNotEmpty == true) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.language_outlined,
                              label: isHindi ? 'वेबसाइट' : 'Official Website',
                              value: datum.officialWebsite!,
                            ),
                          ],

                          if (datum.ownerContact != null &&
                              (datum.ownerContact?.name?.isNotEmpty == true ||
                                  datum.ownerContact?.phone?.isNotEmpty ==
                                      true)) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.person_outline,
                              label: isHindi
                                  ? 'संपर्क व्यक्ति'
                                  : 'Contact Person',
                              value:
                                  '${datum.ownerContact?.name ?? ''} ${datum.ownerContact?.phone != null ? '(${datum.ownerContact!.phone})' : ''}'
                                      .trim(),
                            ),
                          ],

                          if (datum.createdAt != null) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: isHindi ? 'सबमिट तिथि' : 'Submitted Date',
                              value: _formatDate(datum.createdAt),
                            ),
                          ],

                          if (datum.updatedAt != null) ...[
                            SizedBox(height: 10.h),
                            _buildDetailRow(
                              icon: Icons.update_rounded,
                              label: isHindi ? 'अंतिम अपडेट' : 'Last Updated',
                              value: _formatDate(datum.updatedAt),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Action Buttons
                    Row(
                      children: [
                        // Refresh Status Button
                        Expanded(
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: brandGold.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: () {
                                ref.invalidate(getBussinessProfileProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isHindi
                                          ? 'स्थिति ताज़ा की जा रही है...'
                                          : 'Checking latest approval status...',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF0F3D38),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      side: const BorderSide(
                                        color: brandGold,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: const Color(0xFF072420),
                                size: 18.sp,
                              ),
                              label: Text(
                                isHindi ? 'स्थिति जांचें' : 'Check Status',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF072420),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Edit / Update Profile Button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFC5A038),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompanyProfileScreen(
                                    isEdit: true,
                                    existingData: datum,
                                  ),
                                ),
                              ).then((_) {
                                ref.invalidate(getBussinessProfileProvider);
                              });
                            },
                            icon: Icon(
                              Icons.edit_note_rounded,
                              color: brightGold,
                              size: 18.sp,
                            ),
                            label: Text(
                              isHindi ? 'विवरण बदलें' : 'Edit Details',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Back to Dashboard Button
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white60,
                        size: 16.sp,
                      ),
                      label: Text(
                        isHindi ? 'डैशबोर्ड पर वापस जाएं' : 'Back to Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: Colors.white70,
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
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    final local = dt.toLocal();
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
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$min $period';
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailingBadge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white60, size: 16.sp),
        SizedBox(width: 8.w),
        SizedBox(
          width: 120.w,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          ': ',
          style: GoogleFonts.outfit(fontSize: 12.sp, color: Colors.white60),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6.w,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12.5.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailingBadge != null) trailingBadge,
            ],
          ),
        ),
      ],
    );
  }
}

class CompanyProfileRequiredPlaceholder extends StatelessWidget {
  final bool isHindi;
  final String screenTitleEn;
  final String screenTitleHi;
  final VoidCallback onCompleteProfile;
  final ValueChanged<bool>? onLanguageChanged;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CompanyProfileRequiredPlaceholder({
    super.key,
    required this.isHindi,
    required this.screenTitleEn,
    required this.screenTitleHi,
    required this.onCompleteProfile,
    this.onLanguageChanged,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D38),
      key: scaffoldKey,
      drawer: AppDrawer(isHindi: isHindi),
      appBar: AppBarScreen(
        titleEn: screenTitleEn,
        titleHi: screenTitleHi,
        isHindi: isHindi,
        notificationCount: 2,
        onLanguageChanged: (val) {
          if (onLanguageChanged != null) onLanguageChanged!(val);
        },
        onNotificationPressed: () {},
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 460.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(22.r),
                      decoration: BoxDecoration(
                        color: brightGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: brightGold, width: 1.5),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        size: 52.sp,
                        color: brightGold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      isHindi
                          ? 'कंपनी प्रोफ़ाइल आवश्यक है'
                          : 'Company Profile Required',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      isHindi
                          ? 'नौकरी या व्यापार विस्तार के अवसर पोस्ट करने के लिए कृपया पहले अपनी कंपनी प्रोफ़ाइल और कॉर्पोरेट KYC विवरण पूरा करें।'
                          : 'To post job or business expansion opportunities, please complete your company profile and corporate KYC verification first.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5.sp,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: brandGold.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: onCompleteProfile,
                        child: Text(
                          isHindi
                              ? 'कंपनी प्रोफ़ाइल पूरी करें'
                              : 'Complete Company Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF072420),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        isHindi ? 'रद्द करें' : 'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: Colors.white60,
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
    );
  }
}
