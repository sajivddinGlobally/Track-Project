import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/ManageMyApplicationsScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getBusinessOpportunitiesProvider.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/CreateOpportunityReportBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/GetBusinessOpportunitiesResModel.dart';

class ExploreBusinessScreen extends ConsumerStatefulWidget {
  const ExploreBusinessScreen({super.key});

  @override
  ConsumerState<ExploreBusinessScreen> createState() =>
      _ExploreBusinessScreenState();
}

class _ExploreBusinessScreenState extends ConsumerState<ExploreBusinessScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isHindi = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = _searchQuery.trim();
    final isPincode =
        trimmedQuery.isNotEmpty && RegExp(r'^\d+$').hasMatch(trimmedQuery);

    final filter = BusinessOpportunitiesFilter(
      search: !isPincode && trimmedQuery.isNotEmpty ? trimmedQuery : null,
      pincode: isPincode ? trimmedQuery : null,
    );

    final asyncOpportunities = ref.watch(
      getBusinessOpportunitiesProvider(filter),
    );

    return Scaffold(
      drawer: AppDrawer(isHindi: _isHindi),
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      appBar: AppBarScreen(
        titleEn: 'Explore Business Opportunities',
        titleHi: 'व्यापार के अवसर खोजें',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xFFDCDFE4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      hintText: _isHindi
                          ? 'शहर, पिनकोड या व्यापार प्रकार से खोजें...'
                          : 'Search by city, pincode, or business type...',
                      hintStyle: TextStyle(
                        color: Colors.black45,
                        fontSize: 13.sp,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFF0B4F4A),
                        size: 20.sp,
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.h,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18.sp,
                                color: Colors.black45,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Corporate Location Firewall & Intermediary Notice Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFF072420),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              size: 16.sp,
                              color: const Color(0xFF5EEAD4),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _isHindi
                                  ? 'स्थान गोपनीयता सुरक्षा (Corporate Location Firewall)'
                                  : 'Corporate Location Firewall Active',
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5EEAD4),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF14B8A6,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              _isHindi ? '100% सुरक्षित' : 'PROTECTED',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5EEAD4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _isHindi
                            ? 'कंपनियों और नियोक्ताओं के पास आपके GPS स्थान, स्थान इतिहास या निजी सर्कल तक कोई पहुंच नहीं है।'
                            : 'Recruiters and companies have zero access to your GPS location, location history, or private circles.',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _isHindi
                            ? 'मध्यस्थ सूचना: सूचियाँ स्वतंत्र कंपनियों द्वारा सीधे अपलोड की जाती हैं। यह मंच पोस्टिंग की जांच नहीं करता और विवादों के लिए कोई कानूनी दायित्व नहीं रखता। आवेदन करने से पहले स्वयं जांच करें।'
                            : 'Intermediary Notice: Listings are uploaded directly by independent external companies. The Platform does not pre-screen, vet, or verify these postings and holds no legal liability for disputes. Users must perform their own due diligence before applying.',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Section Title & Manage Applications Shortcut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isHindi
                            ? 'सक्रिय विस्तार सूचियाँ'
                            : 'Active Expansion Listings',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageMyApplicationsScreen(
                              initialHindi: _isHindi,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3D38),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(
                              0xFFE6C567,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              color: const Color(0xFFE6C567),
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _isHindi ? 'मेरे आवेदन' : 'My Applications',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE6C567),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Opportunities List from Backend API
                Expanded(
                  child: asyncOpportunities.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48.sp,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              _isHindi
                                  ? 'डेटा लोड करने में समस्या आई'
                                  : 'Failed to load opportunities',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              error.toString(),
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.sp,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0B4F4A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onPressed: () {
                                ref.invalidate(
                                  getBusinessOpportunitiesProvider(filter),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                _isHindi ? 'पुनः प्रयास करें' : 'Retry',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (response) {
                      final list = response.data ?? [];
                      if (list.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_center_outlined,
                                  size: 54.sp,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _isHindi
                                      ? 'कोई व्यापार अवसर नहीं मिला'
                                      : 'No business opportunities found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: const Color(0xFF0B4F4A),
                        backgroundColor: Colors.white,
                        onRefresh: () async {
                          ref.invalidate(
                            getBusinessOpportunitiesProvider(filter),
                          );
                        },
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final location = [item.city, item.state]
                                .where((s) => s != null && s.trim().isNotEmpty)
                                .join(', ');

                            String inv =
                                item.requiredInvest?.toString() ?? 'N/A';
                            if (inv != 'N/A' &&
                                !inv.startsWith('₹') &&
                                !inv.toLowerCase().contains('rs')) {
                              inv = '₹$inv';
                            }

                            final companyName = item.ownerName.isNotEmpty
                                ? item.ownerName
                                : (item.companyType?.isNotEmpty == true
                                      ? item.companyType!
                                      : 'Verified Business');

                            return Container(
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFFDCDFE4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                                vertical: 4.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF0B4F4A,
                                                ).withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(6.r),
                                              ),
                                              child: Text(
                                                item.opportunityType ??
                                                    'Opportunity',
                                                style: TextStyle(
                                                  fontSize: 11.5.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF0B4F4A,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (location.isNotEmpty) ...[
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 14.sp,
                                                      color: const Color(
                                                        0xFF0B4F4A,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Flexible(
                                                      child: Text(
                                                        location,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      // Screen 2: Report Listing Anchor (Applicant Feed Safe Harbor)
                                      InkWell(
                                        onTap: () =>
                                            _showReportAbuseBottomSheet(
                                              context,
                                              item,
                                            ),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withValues(
                                                alpha: 0.25,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.flag_outlined,
                                                size: 13.sp,
                                                color: Colors.red.shade700,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                _isHindi ? 'रिपोर्ट' : 'Report',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    item.opportunityHeadline ??
                                        'Business Opportunity',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    companyName,
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0B4F4A),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    children: [
                                      _infoBadge(
                                        Icons.account_balance_wallet,
                                        _isHindi ? 'निवेश' : 'Investment',
                                        inv,
                                      ),
                                      SizedBox(width: 8.w),
                                      _infoBadge(
                                        Icons.aspect_ratio,
                                        _isHindi ? 'क्षेत्र' : 'Area',
                                        item.area ?? 'N/A',
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      _infoBadge(
                                        Icons.trending_up,
                                        _isHindi ? 'रिटर्न' : 'Returns',
                                        item.expectedReturn?.toString() ??
                                            'N/A',
                                      ),
                                      SizedBox(width: 8.w),
                                      _infoBadge(
                                        Icons.pin_drop,
                                        _isHindi ? 'पिनकोड' : 'Pincode',
                                        item.pincode ?? 'N/A',
                                      ),
                                    ],
                                  ),
                                  if (item.opportunityDescription?.isNotEmpty ==
                                      true) ...[
                                    SizedBox(height: 12.h),
                                    Text(
                                      item.opportunityDescription!,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  SizedBox(height: 16.h),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44.h,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0B4F4A,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                      ),
                                      // Preserved original direct contact call (wrapped inside statutory data transference dialog)
                                      // onPressed: () {
                                      //   _showContactDialog(context, item);
                                      // },
                                      onPressed: () {
                                        _showDataTransferenceDialog(
                                          context,
                                          item,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.send_rounded,
                                        size: 15.sp,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _isHindi
                                            ? 'आवेदन करें / प्रोफ़ाइल साझा करें'
                                            : 'Apply / Share Profile',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 6.h),

                // Dynamic Legal Disclaimer Anchor (Statically Pinned to Feed Stream Bottom)
                InkWell(
                  onTap: () => _showLegalDisclaimersBottomSheet(context),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gavel_rounded,
                          size: 15.sp,
                          color: const Color(0xFFE6C567),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            _isHindi
                                ? 'कानूनी अस्वीकरण (Legal Disclaimers & Intermediary Notice)'
                                : 'Legal Disclaimers & Intermediary Safe Harbor Notice',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE6C567),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFFE6C567),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: const Color(0xFF0B4F4A)),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // Screen 2: The Job Display & Report Abuse System (Applicant Feed View)
  // ========================================================================
  // IT Act Safe Harbor & DPDP Act 2023 Statutory Abuse Reporting Protocol
  // POST /api/v1/business/opportunity-reports
  // ========================================================================
  void _showReportAbuseBottomSheet(
    BuildContext context,
    BusinessOpportunityItem item,
  ) {
    int? selectedReasonIndex;
    final TextEditingController detailsController = TextEditingController();
    File? evidenceFile;
    String? attachedFileName;
    bool isSubmitting = false;

    final reasons = [
      {
        'key': 'fake_job',
        'title': _isHindi
            ? 'फर्जी नौकरी / वित्तीय धोखाधड़ी'
            : 'Fake Job / Financial Scam',
        'desc': _isHindi
            ? '(नियोक्ता पैसे, पंजीकरण शुल्क या बैंक विवरण मांग रहा है)'
            : '(The employer is asking for money, registration fees, or banking details).',
      },
      {
        'key': 'unauthorized_surveillance',
        'title': _isHindi
            ? 'अनधिकृत निगरानी / स्थान अनुरोध'
            : 'Unauthorized Surveillance / Location Request',
        'desc': _isHindi
            ? '(नियोक्ता आपके लाइव स्थान को ट्रैक करने का प्रयास कर रहा है)'
            : '(The employer is attempting to track your location, asking for live coordinates, or bypassing strict B2B boundaries).',
      },
      {
        'key': 'missing_disclosure',
        'title': _isHindi
            ? 'रोजगार-संबंध प्रकटीकरण अनुपस्थित'
            : 'Missing No-Employment Relationship Disclosure',
        'desc': _isHindi
            ? '(कंपनी अवसर की प्रकृति को गलत प्रस्तुत कर रही है)'
            : '(The company is misrepresenting the nature of the opportunity or acting outside standard freelance/business listing).',
      },
      {
        'key': 'suspicious_company',
        'title': _isHindi
            ? 'संदिग्ध / दुर्भावनापूर्ण कंपनी'
            : 'Suspicious / Malicious Company Behavior',
        'desc': _isHindi
            ? '(प्रदान किया गया कंपनी विवरण, ईमेल या नंबर संदिग्ध प्रतीत होता है)'
            : '(The company details, email, or contact number provided seem fraudulent).',
      },
    ];

    Future<void> pickEvidence(StateSetter setSheetState) async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (picked != null) {
          setSheetState(() {
            evidenceFile = File(picked.path);
            attachedFileName = picked.name;
          });
        }
      } catch (e) {
        log('Error picking evidence file: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
              maxWidth: 600.w,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 12.h,
              bottom: bottomInset + 20.h,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 4.5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Header with Alert Badge
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: const Color(0xFFDC2626),
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? 'दुरुपयोग / धोखाधड़ी की रिपोर्ट करें'
                              : 'REPORT ABUSE / FRAUDULENT POSTING',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: Colors.black54,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(sheetCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isHindi
                        ? 'यदि यह नियोक्ता या पोस्टिंग नियमों का उल्लंघन करती है, तो कृपया हमें बताएं। आपकी रिपोर्ट की त्वरित जांच की जाएगी।'
                        : 'If this employer or job posting violates community standards or data rules, please tell us below.',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Select Reason Header
                  Text(
                    _isHindi
                        ? 'रिपोर्टिंग का कारण चुनें (अनिवार्य):'
                        : 'Select reason for reporting (Required):',
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B4F4A),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // List of Reasons
                  ...List.generate(reasons.length, (idx) {
                    final isSelected = selectedReasonIndex == idx;
                    return InkWell(
                      onTap: isSubmitting
                          ? null
                          : () {
                              setSheetState(() => selectedReasonIndex = idx);
                            },
                      borderRadius: BorderRadius.circular(12.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<int>(
                              value: idx,
                              groupValue: selectedReasonIndex,
                              activeColor: const Color(0xFFDC2626),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      setSheetState(
                                        () => selectedReasonIndex = val,
                                      );
                                    },
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reasons[idx]['title']!,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    reasons[idx]['desc']!,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),

                  // Additional Details Input
                  Text(
                    _isHindi
                        ? 'अतिरिक्त विवरण (वैकल्पिक)'
                        : 'Additional Details (Optional)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B4F4A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: detailsController,
                    enabled: !isSubmitting,
                    maxLines: 2,
                    style: TextStyle(color: Colors.black87, fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: _isHindi
                          ? 'वर्णन करें कि क्या हुआ (उदा. शुल्क मांग, अनुचित संदेश)'
                          : 'Please describe what happened (e.g., messages sent outside app, cash demands)',
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black38,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.all(12.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B4F4A),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Proof Attachment Button
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 9.h,
                          ),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () => pickEvidence(setSheetState),
                        icon: Icon(
                          Icons.attach_file_rounded,
                          size: 18.sp,
                          color: const Color(0xFF0B4F4A),
                        ),
                        label: Text(
                          _isHindi
                              ? 'साक्ष्य संलग्न करें (वैकल्पिक)'
                              : 'Attach Proof (Optional)',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            color: const Color(0xFF0B4F4A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (attachedFileName != null) ...[
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attachedFileName!,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF0B4F4A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.cancel,
                                  size: 18.sp,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        setSheetState(() {
                                          evidenceFile = null;
                                          attachedFileName = null;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Safe Facilitator Declaration Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gavel_rounded,
                              size: 16.sp,
                              color: const Color(0xFFD97706),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '⚖️ SAFE FACILITATOR DECLARATION',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _isHindi
                              ? 'Track Loved Ones ऐप केवल एक सूचना मंच के रूप में कार्य करता है। इस पोस्ट की रिपोर्ट करने से तत्काल आंतरिक अनुपालन समीक्षा शुरू होती है। यदि धोखाधड़ी पाई जाती है, तो पोस्ट करने वाली कंपनी को स्थायी रूप से प्रतिबंधित कर दिया जाएगा।'
                              : 'Track Loved Ones App acts strictly as an information venue. Reporting this post triggers an immediate internal compliance review. If fraud is detected, the posting company will be permanently banned.',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Submit Report Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedReasonIndex != null && !isSubmitting
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: selectedReasonIndex != null && !isSubmitting
                            ? 2
                            : 0,
                      ),
                      onPressed: (selectedReasonIndex == null || isSubmitting)
                          ? null
                          : () async {
                              setSheetState(() {
                                isSubmitting = true;
                              });

                              try {
                                final authService = ref.read(
                                  authServiceProvider,
                                );
                                String? evidenceAttachmentUrl;

                                // 1. Evidence image upload if selected
                                if (evidenceFile != null) {
                                  try {
                                    final uploadRes = await authService
                                        .uploadImage(evidenceFile!);
                                    final uploadedUrl =
                                        uploadRes.data?.imageUrl;
                                    if (uploadedUrl != null &&
                                        uploadedUrl.isNotEmpty) {
                                      evidenceAttachmentUrl = uploadedUrl;
                                    }
                                  } catch (e) {
                                    log("Evidence upload failed: $e");
                                  }
                                }

                                // 2. Determine opportunityId
                                final oppId = item.id?.isNotEmpty == true
                                    ? item.id!
                                    : (item.companyId ?? '');

                                final reportBody =
                                    CreateOpportunityReportBodyModel(
                                      postID : oppId,
                                      reasonCategory:
                                          reasons[selectedReasonIndex!]['key'],
                                      additionalDetails:
                                          detailsController.text
                                              .trim()
                                              .isNotEmpty
                                          ? detailsController.text.trim()
                                          : null,
                                      evidenceAttachmentUrl:
                                          evidenceAttachmentUrl,
                                      timestamp: DateTime.now()
                                          .toUtc()
                                          .toIso8601String(),
                                    );

                                // 3. POST /api/v1/business/opportunity-reports
                                final reportResponse = await authService
                                    .createOpportunityReportData(reportBody);

                                if (!ctx.mounted) return;
                                Navigator.pop(sheetCtx);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF0B4F4A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    content: Text(
                                      reportResponse.message ??
                                          (_isHindi
                                              ? 'अवसर रिपोर्ट सफलतापूर्वक दर्ज की गई।'
                                              : 'Opportunity report submitted successfully.'),
                                      style: TextStyle(
                                        fontSize: 13.5.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                log("Create opportunity report error: $e");
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    isSubmitting = false;
                                  });
                                }
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(
                              height: 22.h,
                              width: 22.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Text(
                              _isHindi
                                  ? 'शिकायत अधिकारी को रिपोर्ट सबमिट करें'
                                  : 'SUBMIT REPORT TO GRIEVANCE OFFICER',
                              style: TextStyle(
                                color:
                                    selectedReasonIndex != null && !isSubmitting
                                    ? Colors.white
                                    : Colors.black38,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ========================================================================
  // Section 2.5: Dynamic Legal Disclaimers & Intermediary Safe Harbor Protocol
  // IT Act Section 79 & DPDP Act 2023 Compliance
  // ========================================================================
  void _showLegalDisclaimersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 600.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 12.h,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: const Color(0xFFD97706),
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _isHindi
                          ? 'कानूनी अस्वीकरण एवं सेफ हार्बर'
                          : 'LEGAL DISCLAIMERS & SAFE HARBOR',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20.sp, color: Colors.black54),
                    onPressed: () => Navigator.pop(sheetCtx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Card 1: IT Act Section 79 Intermediary Safe Harbor
              _buildLegalCard(
                icon: Icons.shield_outlined,
                title: _isHindi
                    ? '1. मध्यस्थ सेफ हार्बर (IT Act 2000, Section 79)'
                    : '1. Intermediary Safe Harbor (IT Act 2000, Sec 79)',
                body: _isHindi
                    ? 'Track Loved Ones केवल एक सूचना मध्यस्थ के रूप में कार्य करता है। सभी सूचियाँ बाहरी स्वतंत्र कंपनियों द्वारा सीधे अपलोड की जाती हैं। यह मंच पोस्टिंग की पूर्व-समीक्षा या सत्यापन नहीं करता और किसी भी विवाद, वित्तीय लेन-देन या रोजगार शर्तों के लिए कानूनी रूप से उत्तरदायी नहीं है।'
                    : 'Track Loved Ones acts strictly as an information intermediary. Listings are uploaded directly by independent businesses. The Platform does not pre-screen, vet, or verify postings and holds no legal liability for disputes, salary disagreements, or fraudulent listings. Users must perform independent due diligence.',
              ),
              SizedBox(height: 10.h),

              // Card 2: DPDP Act 2023 & Location Sandbox
              _buildLegalCard(
                icon: Icons.location_off_rounded,
                title: _isHindi
                    ? '2. स्थान गोपनीयता सैंडबॉक्स (Location Firewall)'
                    : '2. Location Privacy Sandbox (DPDP Act, 2023)',
                body: _isHindi
                    ? 'कंपनियों और नियोक्ताओं के पास आपके GPS स्थान, स्थान इतिहास या निजी सुरक्षा सर्कल तक शून्य पहुंच (Zero Access) है। डेटा ट्रांसमिशन विशेष रूप से पुल-टू-सेंड है, जो केवल तभी होता है जब आप स्वयं "Apply" पर क्लिक करते हैं।'
                    : 'Recruiters and companies have zero access to your GPS location, location history, or private family circles. Data transmission is exclusively pull-to-send, triggered only when you explicitly confirm an application.',
              ),
              SizedBox(height: 10.h),

              // Card 3: Independent Data Fiduciary & Erasure
              _buildLegalCard(
                icon: Icons.business_center_outlined,
                title: _isHindi
                    ? '3. स्वतंत्र डेटा फिड्यूशियरी एवं डेटा मिटाने का अधिकार'
                    : '3. Independent Data Fiduciary & Right to Erasure',
                body: _isHindi
                    ? 'डेटा प्रेषित होने के बाद, संबंधित कंपनी DPDP Act 2023 के तहत एक स्वतंत्र डेटा फिड्यूशियरी बन जाती है। आपको कंपनी से सीधे संपर्क करके डेटा संशोधन या पूर्ण विलोपन (Erasure) की मांग करने का वैधानिक अधिकार प्राप्त है।'
                    : 'Upon transmission, the receiving enterprise operates as an independent Data Fiduciary under the DPDP Act, 2023. You retain the absolute statutory right to contact them directly to demand correction, completion, or complete erasure.',
              ),
              SizedBox(height: 10.h),

              // Card 4: Grievance Officer
              _buildLegalCard(
                icon: Icons.mail_outline_rounded,
                title: _isHindi
                    ? '4. शिकायत निवारण अधिकारी (Grievance Officer)'
                    : '4. Grievance Redressal Officer Contact',
                body: _isHindi
                    ? 'नियमों के उल्लंघन या संदिग्ध पोस्टिंग की रिपोर्ट हेतु ईमेल करें: grievance@tracklovedones.com। सभी शिकायतों पर IT रूल्स के तहत 24 घंटे के भीतर संज्ञान लिया जाता है।'
                    : 'For reporting scams, violations, or statutory data rights requests, email: grievance@tracklovedones.com. Acknowledged within 24 hours under Rule 3(2) of IT Rules.',
              ),
              SizedBox(height: 16.h),

              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B4F4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    _isHindi ? 'समझ गया / बंद करें' : 'I Understand / Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: const Color(0xFF0B4F4A)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B4F4A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            body,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // Section 3: The Adult Job Applicant Discretionary Notice (Data Transfer Authorization)
  // Strict DPDP Act, 2023 Statutory Unbundled Consent Flow
  // ========================================================================
  void _showDataTransferenceDialog(
    BuildContext context,
    BusinessOpportunityItem item,
  ) {
    final companyName = item.ownerName.isNotEmpty
        ? item.ownerName
        : (item.companyType?.isNotEmpty == true
              ? item.companyType!
              : 'Business Partner');

    final jobTitle =
        item.opportunityHeadline ?? (item.opportunityType ?? 'Opportunity');
    final TextEditingController preferredLocationController =
        TextEditingController();
    bool isAuthorized = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
              maxWidth: 600.w,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 12.h,
              bottom: bottomInset + 20.h,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 4.5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Header with Lock Icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F4F1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          color: const Color(0xFF0B4F4A),
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? 'आवेदन एवं प्रोफ़ाइल साझाकरण पुष्टि'
                              : 'CONFIRM JOB APPLICATION & PROFILE SHARING',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B4F4A),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    _isHindi
                        ? 'आप अवसर "$jobTitle" के लिए $companyName के साथ अपनी व्यावसायिक प्रोफ़ाइल साझा करने जा रहे हैं।'
                        : 'You are about to share your professional profile with $companyName for the opportunity: $jobTitle.',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Static Information Packet transferred Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FB),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHindi
                              ? 'हस्तांतरित होने वाला विशिष्ट स्थिर डेटा पैकेट:'
                              : 'Specific static information packet being transferred:',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B4F4A),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 17.sp,
                              color: const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Full Professional Name',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 17.sp,
                              color: const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Verified Mobile Number & Email Address',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 17.sp,
                              color: const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Uploaded Resume Document (.pdf/.docx)',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Location Preference Discretion (GPS Stripped Notice)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFBBF7D0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 18.sp,
                              color: const Color(0xFF16A34A),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '📍 LOCATION PRIVACY PROTECTION',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _isHindi
                              ? 'हमारी गोपनीयता नीति के तहत, आपका रीयल-टाइम GPS स्थान और ट्रैकिंग इतिहास इस ट्रांसमिशन से पूर्णतः हटा दिया गया है। नियोक्ता आपको ट्रैक नहीं कर सकता।'
                              : 'Under our privacy guardrails, your real-time GPS location and tracking history are completely stripped from this transmission. The employer cannot track you.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF166534),
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _isHindi
                              ? 'यदि आप अपनी पसंद का कार्य स्थान दर्ज करना चाहते हैं, तो नीचे टाइप करें (वैकल्पिक):'
                              : 'If you wish to state a preferred work location, please type it below at your own discretion:',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: preferredLocationController,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'e.g., New Delhi, Work From Remote',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black38,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF0B4F4A),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // The 4 Statutory Compliance Pillars Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 16.sp,
                              color: const Color(0xFFD97706),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _isHindi
                                  ? 'आवेदन पुष्टि एवं वैधानिक शर्तें'
                                  : 'TERMS OF APPLICATION & DATA TRANSFER',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _buildTransferenceBullet(
                          title: _isHindi
                              ? '• शून्य ऐप दायित्व (Zero App Liability):'
                              : '• Zero App Liability:',
                          desc: _isHindi
                              ? 'Track Loved Ones केवल एक सूचना मध्यस्थ है। हम इस नियोक्ता की जांच या सत्यापन नहीं करते। रोजगार शर्तों, धोखाधड़ी या बातचीत के लिए ऐप उत्तरदायी नहीं होगा।'
                              : 'You acknowledge that Track Loved Ones acts strictly as an information mediator. We do not vet or verify this employer. The Platform holds no responsibility or liability for employment terms, scams, or interactions resulting from this application.',
                        ),
                        SizedBox(height: 6.h),
                        _buildTransferenceBullet(
                          title: _isHindi
                              ? '• प्राइवेसी सैंडबॉक्स (Privacy Sandbox):'
                              : '• Privacy Sandbox:',
                          desc: _isHindi
                              ? 'इस कंपनी के पास आपके लाइव स्थान ट्रैकिंग या निजी सुरक्षा सर्कल तक शून्य पहुंच (Zero Access) है।'
                              : 'This company has zero access to your live location tracking or private safety circles.',
                        ),
                        SizedBox(height: 6.h),
                        _buildTransferenceBullet(
                          title: _isHindi
                              ? '• स्वतंत्र डेटा फिड्यूशियरी (Independent Data Fiduciary):'
                              : '• Independent Data Fiduciary:',
                          desc: _isHindi
                              ? 'ट्रांसमिशन के बाद, $companyName DPDPA 2023 के तहत एक स्वतंत्र डेटा फिड्यूशियरी बन जाएगी।'
                              : 'Upon transmission, $companyName becomes an independent Data Fiduciary under the DPDPA, 2023.',
                        ),
                        SizedBox(height: 6.h),
                        _buildTransferenceBullet(
                          title: _isHindi
                              ? '• डेटा सुधार व मिटाने का अधिकार (Right to Erasure):'
                              : '• Statutory Data Rights:',
                          desc: _isHindi
                              ? 'आपके पास सीधे कंपनी से संपर्क करके अपने डेटा को सुधारने या पूर्णतः मिटाने (Erasure) की मांग करने का वैधानिक अधिकार सुरक्षित है।'
                              : 'You retain the absolute right to contact them directly to demand data correction or complete erasure.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Mandatory Authorization Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isAuthorized,
                        activeColor: const Color(0xFF0B4F4A),
                        checkColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (val) {
                          setModalState(() => isAuthorized = val ?? false);
                        },
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? '(अनिवार्य) \'Confirm\' पर क्लिक करके, मैं Track Loved Ones को इन कानूनी शर्तों के तहत अपनी प्रोफ़ाइल नाम, संपर्क विवरण और बायोडाटा $companyName को प्रेषित करने का स्पष्ट निर्देश देता/देती हूँ।'
                              : '(Required) By clicking "Confirm", you explicitly direct Track Loved Ones to transmit your profile name, contact details, and resume text to $companyName under these statutory terms.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAuthorized
                            ? const Color(0xFF0B4F4A)
                            : const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: isAuthorized ? 2 : 0,
                      ),
                      onPressed: !isAuthorized
                          ? null
                          : () {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0B4F4A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  content: Text(
                                    _isHindi
                                        ? 'प्रोफ़ाइल सुरक्षित रूप से प्रेषित की गई। नियोक्ता संपर्क विवरण प्रदर्शित किए जा रहे हैं।'
                                        : 'Profile packet transmitted under DPDP consent. Revealing employer contact.',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                              // Proceed to contact display
                              _showContactDialog(context, item);
                            },
                      child: Text(
                        _isHindi
                            ? 'पुष्टि करें एवं आवेदन प्रेषित करें'
                            : 'CONFIRM & TRANSMIT APPLICATION',
                        style: TextStyle(
                          color: isAuthorized ? Colors.white : Colors.black38,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransferenceBullet({
    required String title,
    required String desc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF92400E),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          desc,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF78350F),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  void _showContactDialog(BuildContext context, BusinessOpportunityItem item) {
    final companyName = item.ownerName.isNotEmpty
        ? item.ownerName
        : (item.companyType?.isNotEmpty == true
              ? item.companyType!
              : 'Business Partner');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          companyName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isHindi
                  ? 'इस विस्तार अवसर के प्रतिनिधि से संपर्क करें:'
                  : 'Get in touch with the representative for this expansion opportunity:',
              style: TextStyle(fontSize: 13.sp, color: Colors.black54),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.contactPersonName?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16.sp,
                          color: const Color(0xFF0B4F4A),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item.contactPersonName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                  if (item.mobileNumber?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16.sp,
                          color: const Color(0xFF0B4F4A),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item.mobileNumber!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                  if (item.businessEmail?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 16.sp,
                          color: const Color(0xFF0B4F4A),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item.businessEmail!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B4F4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              _isHindi ? 'बंद करें' : 'Close',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
