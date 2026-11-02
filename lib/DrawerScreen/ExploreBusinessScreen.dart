import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getBusinessOpportunitiesProvider.dart';
import 'package:track_loved/DrawerScreen/provider/getMyJobApplicationsProvider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/CreateOpportunityReportBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/GetBusinessOpportunitiesResModel.dart';

class ExploreBusinessScreen extends ConsumerStatefulWidget {
  const ExploreBusinessScreen({super.key});

  @override
  ConsumerState<ExploreBusinessScreen> createState() =>
      _ExploreBusinessScreenState();
}

class _ExploreBusinessScreenState extends ConsumerState<ExploreBusinessScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isHindi = false;
  String _searchQuery = '';
  bool _isFirewallBannerExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('userdata');
    var role = box.get('role');
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
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 80;

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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: isKeyboardOpen ? 8.h : 12.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    height: 44.h,
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
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        hintText: _isHindi
                            ? 'शहर, पिनकोड या व्यापार प्रकार से खोजें...'
                            : 'Search by city, pincode, or business type...',
                        hintStyle: TextStyle(
                          color: Colors.black45,
                          fontSize: 12.5.sp,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF0B4F4A),
                          size: 19.sp,
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
                  SizedBox(height: isKeyboardOpen ? 8.h : 12.h),
                  // Corporate Location Firewall & Intermediary Notice Banner (Responsive & Collapsible)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isFirewallBannerExpanded = !_isFirewallBannerExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: (isKeyboardOpen || !_isFirewallBannerExpanded)
                            ? 7.h
                            : 10.h,
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
                                  size: 15.sp,
                                  color: const Color(0xFF5EEAD4),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _isHindi
                                      ? 'स्थान गोपनीयता सुरक्षा (Firewall Active)'
                                      : 'Corporate Location Firewall Active',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5EEAD4),
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5EEAD4),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                (isKeyboardOpen || !_isFirewallBannerExpanded)
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                color: const Color(0xFF5EEAD4),
                                size: 18.sp,
                              ),
                            ],
                          ),
                          if (!isKeyboardOpen && _isFirewallBannerExpanded) ...[
                            SizedBox(height: 6.h),
                            Text(
                              _isHindi
                                  ? 'कंपनियों और नियोक्ताओं के पास आपके GPS स्थान, स्थान इतिहास या निजी सर्कल तक कोई पहुंच नहीं है।'
                                  : 'Recruiters and companies have zero access to your GPS location, location history, or private circles.',
                              style: TextStyle(
                                fontSize: 12.sp,
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
                                fontSize: 11.sp,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
                    SizedBox(height: 12.h),
                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _isHindi
                                ? 'व्यापार एवं नौकरी के अवसर'
                                : 'Explore Opportunities & Jobs',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ] else ...[
                    SizedBox(height: 6.h),
                  ],
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
                        final rawBusiness = response.businessPosts;
                        final rawJobs = response.jobPosts;

                        bool isJobItem(BusinessOpportunityItem item) {
                          if ((item.requiredInvest != null &&
                                  item.requiredInvest.toString() != '0') ||
                              (item.opportunityType != null &&
                                  item.opportunityType!.trim().isNotEmpty) ||
                              (item.opportunityHeadline != null &&
                                  item.opportunityHeadline!
                                      .trim()
                                      .isNotEmpty)) {
                            return false;
                          }
                          return item.isJob;
                        }

                        final businessList = rawBusiness
                            .where((item) => !isJobItem(item))
                            .toList();

                        final Set<String> seenJobIds = {};
                        final List<BusinessOpportunityItem> jobList = [];
                        for (final j in [
                          ...rawJobs,
                          ...rawBusiness.where((item) => isJobItem(item)),
                        ]) {
                          final id = j.id ?? '_';
                          if (!seenJobIds.contains(id)) {
                            seenJobIds.add(id);
                            jobList.add(j);
                          }
                        }

                        final filteredBusiness = _filterList(
                          businessList,
                          _searchQuery,
                        );
                        final filteredJobs = _filterList(jobList, _searchQuery);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tab Bar for Business vs Jobs
                            TabBar(
                              padding: EdgeInsets.zero,
                              labelPadding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                              ),
                              controller: _tabController,
                              indicatorColor: const Color(0xFFE6C567),
                              indicatorWeight: 3,
                              labelColor: const Color(0xFFE6C567),
                              unselectedLabelColor: Colors.white70,
                              labelStyle: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w500,
                              ),

                              tabs: [
                                Tab(
                                  height: 38.h,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.business_center_rounded,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Flexible(
                                        child: Text(
                                          _isHindi
                                              ? 'व्यापार अवसर'
                                              : 'Business',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tab(
                                  height: 38.h,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.work_rounded, size: 16.sp),
                                      SizedBox(width: 6.w),
                                      Flexible(
                                        child: Text(
                                          _isHindi
                                              ? 'नौकरी अवसर'
                                              : 'Job Openings',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isKeyboardOpen ? 6.h : 10.h),
                            // TabBarView Content
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildBusinessTab(
                                    filteredBusiness,
                                    role,
                                    filter,
                                  ),
                                  _buildJobsTab(filteredJobs, role, filter),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTab(
    List<BusinessOpportunityItem> list,
    String? role,
    BusinessOpportunitiesFilter filter,
  ) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0B4F4A),
      backgroundColor: Colors.white,
      onRefresh: () async {
        ref.invalidate(getBusinessOpportunitiesProvider(filter));
      },
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildBusinessOpportunityCard(item, role);
        },
      ),
    );
  }

  Widget _buildJobsTab(
    List<BusinessOpportunityItem> list,
    String? role,
    BusinessOpportunitiesFilter filter,
  ) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 54.sp,
                  color: Colors.white38,
                ),
                SizedBox(height: 12.h),
                Text(
                  _isHindi
                      ? 'कोई नौकरी का अवसर नहीं मिला'
                      : 'No job openings found',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0B4F4A),
      backgroundColor: Colors.white,
      onRefresh: () async {
        ref.invalidate(getBusinessOpportunitiesProvider(filter));
      },
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildJobOpeningCard(item, role);
        },
      ),
    );
  }

  Widget _buildBusinessOpportunityCard(
    BusinessOpportunityItem item,
    String? role,
  ) {
    final location = [
      item.city,
      item.state,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    final inv = _formatInvestment(item.requiredInvest);

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
        border: Border.all(color: const Color(0xFFDCDFE4), width: 1),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B4F4A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item.opportunityType ?? 'Opportunity',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B4F4A),
                        ),
                      ),
                    ),
                    if (item.companyType != null &&
                        item.companyType!.trim().isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.companyType!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    if (location.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14.sp,
                            color: const Color(0xFF0B4F4A),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (role == "user")
                InkWell(
                  onTap: () => _showReportAbuseBottomSheet(context, item),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.25),
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
                          _isHindi ? 'à¤°à¤¿à¤ªà¥‹à¤°à¥à¤Ÿ' : 'Report',
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
            item.opportunityHeadline ?? 'Business Opportunity',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
                _isHindi ? 'à¤•à¥à¤·à¥‡à¤¤à¥à¤°' : 'Area',
                item.area ?? 'N/A',
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _infoBadge(
                Icons.trending_up,
                _isHindi ? 'à¤°à¤¿à¤Ÿà¤°à¥à¤¨' : 'Returns',
                item.expectedReturn?.toString() ?? 'N/A',
              ),
              SizedBox(width: 8.w),
              _infoBadge(
                Icons.pin_drop,
                _isHindi ? 'à¤ªà¤¿à¤¨à¤•à¥‹à¤¡' : 'Pincode',
                item.pincode ?? 'N/A',
              ),
            ],
          ),
          if (item.opportunityDescription?.isNotEmpty == true) ...[
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
          if (role == "user")
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4F4A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () {
                  _showDataTransferenceDialog(context, item);
                },
                icon: Icon(
                  Icons.send_rounded,
                  size: 15.sp,
                  color: Colors.white,
                ),
                label: Text(
                  _isHindi
                      ? 'à¤†à¤µà¥‡à¤¦à¤¨ à¤•à¤°à¥‡à¤‚ / à¤ªà¥à¤°à¥‹à¤«à¤¼à¤¾à¤‡à¤² à¤¸à¤¾à¤à¤¾ à¤•à¤°à¥‡à¤‚'
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
  }

  Widget _buildJobOpeningCard(BusinessOpportunityItem item, String? role) {
    final location = [
      item.city,
      item.state,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    final ctc = _formatCtc(item.annualCtcPackage);

    final employerName = item.ownerName.isNotEmpty
        ? item.ownerName
        : (item.companyType?.isNotEmpty == true
              ? item.companyType!
              : 'Hiring Company');

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDCDFE4), width: 1),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B4F4A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        (item.employmentType?.isNotEmpty == true
                                ? item.employmentType!
                                : 'Full-Time')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B4F4A),
                        ),
                      ),
                    ),
                    if (item.hierarchyLevel?.isNotEmpty == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.hierarchyLevel!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    if (location.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14.sp,
                            color: const Color(0xFF0B4F4A),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (role == "user")
                InkWell(
                  onTap: () => _showReportAbuseBottomSheet(context, item),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.25),
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
                          _isHindi ? 'à¤°à¤¿à¤ªà¥‹à¤°à¥à¤Ÿ' : 'Report',
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
            item.jobTitle ?? 'Job Opportunity',
            style: TextStyle(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _infoBadge(
                Icons.currency_rupee_rounded,
                _isHindi
                    ? 'à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤ªà¥ˆà¤•à¥‡à¤œ'
                    : 'Annual CTC',
                ctc,
              ),
              SizedBox(width: 8.w),
              _infoBadge(
                Icons.pin_drop,
                _isHindi ? 'à¤ªà¤¿à¤¨à¤•à¥‹à¤¡' : 'Pincode',
                item.pincode ?? 'N/A',
              ),
            ],
          ),
          if (item.jobDescription?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            Text(
              item.jobDescription!,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black54,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.requirements != null && item.requirements!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              _isHindi
                  ? 'à¤†à¤µà¤¶à¥à¤¯à¤• à¤¯à¥‹à¤—à¥à¤¯à¤¤à¤¾ / à¤•à¥Œà¤¶à¤²:'
                  : 'Key Requirements:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: item.requirements!.take(4).map((req) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 12.sp,
                        color: const Color(0xFF0B4F4A),
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          req,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (item.perksAndBenefits != null &&
              item.perksAndBenefits!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: item.perksAndBenefits!.take(3).map((perk) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 12.sp,
                        color: const Color(0xFF92400E),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        perk,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 16.h),
          if (role == "user")
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4F4A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () {
                  _showDataTransferenceDialog(context, item);
                },
                icon: Icon(
                  Icons.send_rounded,
                  size: 15.sp,
                  color: Colors.white,
                ),
                label: Text(
                  _isHindi
                      ? 'à¤†à¤µà¥‡à¤¦à¤¨ à¤•à¤°à¥‡à¤‚ / à¤ªà¥à¤°à¥‹à¤«à¤¼à¤¾à¤‡à¤² à¤¸à¤¾à¤à¤¾ à¤•à¤°à¥‡à¤‚'
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
  }

  String _formatInvestment(dynamic inv) {
    if (inv == null) return 'N/A';
    final rawStr = inv.toString().trim();
    if (rawStr.isEmpty) return 'N/A';

    if (rawStr.toLowerCase().contains('lakh') ||
        rawStr.toLowerCase().contains('lac') ||
        rawStr.toLowerCase().contains('cr') ||
        rawStr.toLowerCase().contains('crore') ||
        rawStr.toLowerCase().contains('k')) {
      if (!rawStr.startsWith('₹') && !rawStr.toLowerCase().contains('rs')) {
        return '₹$rawStr';
      }
      return rawStr;
    }

    num? val;
    if (inv is num) {
      val = inv;
    } else {
      val = num.tryParse(rawStr.replaceAll(RegExp(r'[^\d.]'), ''));
    }

    if (val != null) {
      if (val >= 10000000) {
        final cr = val / 10000000;
        final formattedCr = (cr == cr.roundToDouble())
            ? cr.toInt().toString()
            : cr.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
        return '₹$formattedCr Cr';
      } else if (val >= 100000) {
        final lacs = val / 100000;
        final formattedLacs = (lacs == lacs.roundToDouble())
            ? lacs.toInt().toString()
            : lacs.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
        return '₹$formattedLacs Lakhs';
      } else {
        return '₹$val';
      }
    }

    if (!rawStr.startsWith('₹') && !rawStr.toLowerCase().contains('rs')) {
      return '₹$rawStr';
    }
    return rawStr;
  }

  String _formatCtc(dynamic ctc) {
    if (ctc == null) return 'Disclosed on apply';
    final rawStr = ctc.toString().trim();
    if (rawStr.isEmpty) return 'Disclosed on apply';

    if (rawStr.toLowerCase().contains('lpa') ||
        rawStr.toLowerCase().contains('lakh') ||
        rawStr.toLowerCase().contains('cr')) {
      if (!rawStr.startsWith('₹') && !rawStr.toLowerCase().contains('rs')) {
        return '₹$rawStr';
      }
      return rawStr;
    }

    num? val;
    if (ctc is num) {
      val = ctc;
    } else {
      val = num.tryParse(rawStr.replaceAll(RegExp(r'[^\d.]'), ''));
    }
    if (val == null || val <= 0) return 'Disclosed on apply';

    if (val >= 10000000) {
      final cr = val / 10000000;
      final formattedCr = (cr == cr.roundToDouble())
          ? cr.toInt().toString()
          : cr.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '₹$formattedCr Cr PA';
    } else if (val >= 100000) {
      final lacs = val / 100000;
      final formattedLacs = (lacs == lacs.roundToDouble())
          ? lacs.toInt().toString()
          : lacs.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      return '₹$formattedLacs LPA';
    }
    return '₹$val / yr';
  }

  List<BusinessOpportunityItem> _filterList(
    List<BusinessOpportunityItem> list,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((item) {
      final title =
          (item.isJob ? item.jobTitle : item.opportunityHeadline) ?? '';
      final type = item.opportunityType ?? '';
      final empType = item.employmentType ?? '';
      final city = item.city ?? '';
      final state = item.state ?? '';
      final pin = item.pincode ?? '';
      final company = item.ownerName;
      final reqs = item.requirements?.join(' ') ?? '';
      return title.toLowerCase().contains(q) ||
          type.toLowerCase().contains(q) ||
          empType.toLowerCase().contains(q) ||
          city.toLowerCase().contains(q) ||
          state.toLowerCase().contains(q) ||
          pin.toLowerCase().contains(q) ||
          company.toLowerCase().contains(q) ||
          reqs.toLowerCase().contains(q);
    }).toList();
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
                                      postID: oppId,
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
        item.jobTitle ??
        item.opportunityHeadline ??
        (item.opportunityType ?? 'Opportunity');

    final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
    final initialName = box?.get('name')?.toString() ?? '';
    final initialEmail = box?.get('email')?.toString() ?? '';
    final initialPhone =
        box?.get('phone')?.toString() ?? box?.get('mobile')?.toString() ?? '';

    final TextEditingController nameController = TextEditingController(
      text: initialName,
    );
    final TextEditingController emailController = TextEditingController(
      text: initialEmail,
    );
    final TextEditingController phoneController = TextEditingController(
      text: initialPhone,
    );
    final TextEditingController commentController = TextEditingController();
    bool isAuthorized = false;
    PlatformFile? selectedResumeFile;
    bool isPickingFile = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
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

                  // ==========================================================
                  // 👤 APPLICANT INFORMATION FORM CARD
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 18.sp,
                              color: const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _isHindi
                                  ? 'आवेदक प्रोफ़ाइल विवरण (हस्तांतरित डेटा):'
                                  : 'Applicant Profile Details (Transmitted Data):',
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B4F4A),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildApplyInputField(
                          label: _isHindi
                              ? 'पूरा नाम *'
                              : 'Applicant Full Name *',
                          controller: nameController,
                          hintText: _isHindi
                              ? 'अपना नाम दर्ज करें'
                              : 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                        SizedBox(height: 10.h),
                        _buildApplyInputField(
                          label: _isHindi
                              ? '10-अंकीय मोबाइल नंबर *'
                              : '10-Digit Mobile Number *',
                          controller: phoneController,
                          hintText: 'e.g. 9876543210',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 10.h),
                        _buildApplyInputField(
                          label: _isHindi ? 'ईमेल पता *' : 'Email Address *',
                          controller: emailController,
                          hintText: 'candidate@example.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // ==========================================================
                  // 📄 UPLOAD RESUME / PROPOSAL DOCUMENT (.PDF / .DOC / .DOCX) CARD
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: selectedResumeFile != null
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selectedResumeFile != null
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFCBD5E1),
                        width: selectedResumeFile != null ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              selectedResumeFile != null
                                  ? Icons.file_present_rounded
                                  : Icons.upload_file_rounded,
                              size: 18.sp,
                              color: selectedResumeFile != null
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _isHindi
                                    ? 'बायोडाटा दस्तावेज़ (.pdf, .doc, .docx - अधिकतम 5MB):'
                                    : 'Attach Resume Document (.pdf, .doc, .docx - Max 5MB):',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B4F4A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        if (selectedResumeFile == null) ...[
                          Text(
                            _isHindi
                                ? 'कंपनी को भेजने के लिए अपना बायोडाटा (.pdf, .doc, .docx) चुनें (अधिकतम 5 MB):'
                                : 'Select your professional resume (.pdf, .doc, .docx) to transmit to the employer (Max 5 MB):',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          InkWell(
                            onTap: isPickingFile
                                ? null
                                : () async {
                                    setModalState(() => isPickingFile = true);
                                    try {
                                      final result = await FilePicker.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: [
                                          'pdf',
                                          'doc',
                                          'docx',
                                        ],
                                      );
                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        final picked = result.files.first;
                                        if (picked.size > 5 * 1024 * 1024) {
                                          if (sheetCtx.mounted) {
                                            ScaffoldMessenger.of(
                                              sheetCtx,
                                            ).showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                    Colors.redAccent,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                content: Text(
                                                  _isHindi
                                                      ? 'बायोडाटा फ़ाइल का आकार 5 MB से कम होना चाहिए।'
                                                      : 'Resume file size must be less than 5 MB.',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          setModalState(() {
                                            selectedResumeFile = picked;
                                          });
                                        }
                                      }
                                    } catch (e) {
                                      log('FilePicker error: $e');
                                    } finally {
                                      setModalState(
                                        () => isPickingFile = false,
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: 11.h,
                                horizontal: 14.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isPickingFile) ...[
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0B4F4A),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                  ] else ...[
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 18.sp,
                                      color: const Color(0xFF0B4F4A),
                                    ),
                                    SizedBox(width: 8.w),
                                  ],
                                  Text(
                                    _isHindi
                                        ? 'दस्तावेज़ चुनें (.pdf / .doc / .docx)'
                                        : 'Select Resume (.pdf / .doc / .docx)',
                                    style: TextStyle(
                                      color: const Color(0xFF0B4F4A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // File Attached Info Card
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.h,
                              horizontal: 12.w,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E8),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: const Color(0xFFDC2626),
                                    size: 22.sp,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedResumeFile!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.sp,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${(selectedResumeFile!.size / 1024).toStringAsFixed(1)} KB • Attached for Transmission',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF16A34A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                InkWell(
                                  onTap: () {
                                    setModalState(
                                      () => selectedResumeFile = null,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18.sp,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // ==========================================================
                  // 📝 OPTIONAL COMMENT / NOTE CARD
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 19.sp,
                              color: const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _isHindi
                                  ? 'टिप्पणी / संदेश (वैकल्पिक):'
                                  : 'Comment / Note to Employer (Optional):',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B4F4A),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: commentController,
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13.5.sp,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: _isHindi
                                ? 'नियोक्ता के लिए कोई संदेश या पसंदीदा कार्य स्थान...'
                                : 'e.g. Interested in this role, immediately available...',
                            hintStyle: TextStyle(
                              fontSize: 12.5.sp,
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

                  // ⚠️ NO-EMPLOYER RELATIONSHIP NOTICE
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16.sp,
                              color: const Color(0xFFDC2626),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _isHindi
                                  ? '⚠️ कोई नियोक्ता संबंध नहीं सूचना (NO-EMPLOYER NOTICE)'
                                  : '⚠️ NO-EMPLOYER RELATIONSHIP NOTICE:',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          _isHindi
                              ? 'आवेदन करके, आप स्वीकार करते हैं कि Track Loved Ones App स्वतंत्र पक्षों को जोड़ने वाला केवल एक सूचना स्थल है। यह ऐप आपको रोजगार नहीं देता, अवसर को प्रायोजित नहीं करता, कार्यस्थलों की जांच नहीं करता या भर्ती एजेंसी के रूप में कार्य नहीं करता। इस प्रोफ़ाइल को सबमिट करने से आपके और ऐप के बीच कोई सेवा अनुबंध या श्रम सुरक्षा स्थापित नहीं होती है।'
                              : 'By tapping apply, you acknowledge that Track Loved Ones App is strictly an information venue linking independent parties. Track Loved Ones App does not employ you, sponsor the opportunity, screen employer workplaces, or act as a hiring agency. No employment relationship, contract of service, or labor protections are established between you and Track Loved Ones App by submitting this profile.',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF991B1B),
                            height: 1.35,
                          ),
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
                              ? '(अनिवार्य) मैं Track Loved Ones App को इस स्थिर बायोडाटा पैकेट को नियोक्ता ($companyName) को प्रेषित करने के लिए अधिकृत करता/करती हूँ। मैं समझता/समझती हूँ कि मैं इस आवेदन को कभी भी वापस ले सकता/सकती हूँ, जिससे नियोक्ता को मेरा डेटा मिटाने का संकेत मिलेगा।'
                              : '(Required) I authorize Track Loved Ones App to transmit this static resume packet to the employer ($companyName). I understand I can withdraw this application at any time, signaling the employer to erase my data.',
                          style: TextStyle(
                            fontSize: 12.5.sp,
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
                        backgroundColor: (isAuthorized && !isSubmitting)
                            ? const Color(0xFF0B4F4A)
                            : const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: (isAuthorized && !isSubmitting) ? 2 : 0,
                      ),
                      onPressed: (!isAuthorized || isSubmitting)
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final email = emailController.text.trim();
                              final phone = phoneController.text.trim();
                              final comment = commentController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      _isHindi
                                          ? 'कृपया अपना पूरा नाम दर्ज करें।'
                                          : 'Please enter your full name.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final cleanPhone = phone.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (cleanPhone.length < 10) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      _isHindi
                                          ? 'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें।'
                                          : 'Please enter a valid 10-digit mobile number.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (email.isEmpty ||
                                  !email.contains('@') ||
                                  !email.contains('.')) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      _isHindi
                                          ? 'कृपया एक मान्य ईमेल पता दर्ज करें।'
                                          : 'Please enter a valid email address.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final postId = item.id ?? '';
                              if (postId.isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      _isHindi
                                          ? 'अमान्य पोस्ट आईडी।'
                                          : 'Invalid post ID.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                File? resumeFile;
                                if (selectedResumeFile?.path != null) {
                                  resumeFile = File(selectedResumeFile!.path!);
                                }

                                final response = await ref
                                    .read(authServiceProvider)
                                    .applyJobProfileData(
                                      postId: postId,
                                      name: name,
                                      email: email,
                                      phone: phone,
                                      comment: comment.isNotEmpty
                                          ? comment
                                          : null,
                                      resume: resumeFile,
                                    );

                                ref.invalidate(getMyJobApplicationsProvider);

                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF0B4F4A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      content: Text(
                                        response.message ??
                                            (_isHindi
                                                ? 'आवेदन एवं प्रोफ़ाइल सुरक्षित रूप से जमा की गई।'
                                                : 'Application and profile submitted successfully!'),
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                  _showContactDialog(context, item);
                                }
                              } catch (e) {
                                log('Apply Job Profile Error: $e');
                                if (sheetCtx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      content: Text(
                                        _isHindi
                                            ? 'आवेदन सबमिट करने में त्रुटि: ${e.toString().replaceAll('Exception: ', '')}'
                                            : 'Failed to submit application: ${e.toString().replaceAll('Exception: ', '')}',
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(
                              width: 22.w,
                              height: 22.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isHindi
                                  ? '🚀 प्रोफ़ाइल साझा करें एवं आवेदन जमा करें'
                                  : '🚀 SHARE PROFILE AND SUBMIT APPLICATION',
                              style: TextStyle(
                                color: isAuthorized
                                    ? Colors.white
                                    : Colors.black38,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
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

  Widget _buildApplyInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B4F4A),
          ),
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.black87, fontSize: 13.5.sp),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 12.5.sp, color: Colors.black38),
            prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF0B4F4A)),
            prefixIconConstraints: BoxConstraints(
              minWidth: 36.w,
              minHeight: 36.h,
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 9.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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
    );
  }

  void _showContactDialog(BuildContext context, BusinessOpportunityItem item) {
    final companyName = item.ownerName.isNotEmpty
        ? item.ownerName
        : (item.companyType?.isNotEmpty == true
              ? item.companyType!
              : 'Business Partner');

    final contactName = item.contactPersonName?.isNotEmpty == true
        ? item.contactPersonName
        : (item.ownerName.isNotEmpty ? item.ownerName : null);
    final contactPhone = item.mobileNumber?.isNotEmpty == true
        ? item.mobileNumber
        : item.applicationContactPhone;
    final contactEmail = item.businessEmail?.isNotEmpty == true
        ? item.businessEmail
        : item.applicationContactEmail;

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
              item.isJob
                  ? (_isHindi
                        ? 'इस नौकरी अवसर के प्रतिनिधि से संपर्क करें:'
                        : 'Get in touch with the employer for this job opening:')
                  : (_isHindi
                        ? 'इस विस्तार अवसर के प्रतिनिधि से संपर्क करें:'
                        : 'Get in touch with the representative for this expansion opportunity:'),
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
                  if (contactName?.isNotEmpty == true) ...[
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
                            contactName!,
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
                  if (contactPhone?.isNotEmpty == true) ...[
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
                            contactPhone!,
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
                  if (contactEmail?.isNotEmpty == true) ...[
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
                            contactEmail!,
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
