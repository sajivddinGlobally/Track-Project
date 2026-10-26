import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/provider/getBusinessOpportunitiesProvider.dart';
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
                SizedBox(height: 16.h),

                // Section Title
                Row(
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
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0B4F4A,
                                          ).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
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
                                      onPressed: () {
                                        _showContactDialog(context, item);
                                      },
                                      icon: Icon(
                                        Icons.phone,
                                        size: 16.sp,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _isHindi
                                            ? 'व्यापार भागीदार से संपर्क करें'
                                            : 'Contact Business Partner',
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
