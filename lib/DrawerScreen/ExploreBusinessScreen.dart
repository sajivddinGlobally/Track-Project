import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';

class ExploreBusinessScreen extends StatefulWidget {
  const ExploreBusinessScreen({super.key});

  @override
  State<ExploreBusinessScreen> createState() => _ExploreBusinessScreenState();
}

class _ExploreBusinessScreenState extends State<ExploreBusinessScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isHindi = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _opportunities = [
    {
      'company': 'SwiftLogistics Express',
      'type': 'Start Courier Business / Franchise',
      'title': 'Looking for City Distributors for Fast Courier Service',
      'location': 'Faridabad / Delhi NCR',
      'pincode': '121001',
      'investment': '₹2 Lakhs - ₹5 Lakhs',
      'area': '150 - 300 Sq. Ft.',
      'returns': '20-25% ROI or Payback within 6 Months',
      'description':
          'Full technology platform, sorting software, uniform kits, and initial branding support provided. Great scope for local last-mile delivery growth.',
      'contactPerson': 'Rajesh Verma (Director)',
      'phone': '+91 98765 43210',
      'email': 'partners@swiftlogistics.com',
    },
    {
      'company': 'Apex Organic Retail Chain',
      'type': 'Retail Franchise Store',
      'title': 'Super Stockist & Retail Partner for Organic Grocery Products',
      'location': 'Gurugram / Haryana',
      'pincode': '122001',
      'investment': '₹5 Lakhs - ₹10 Lakhs',
      'area': '400 - 600 Sq. Ft.',
      'returns': '25-30% Margin with Guaranteed Buyback Support',
      'description':
          'Exclusive regional stockist rights for high-margin healthy snack lines and organic staple goods. Complete store setup and marketing material included.',
      'contactPerson': 'Sunil Malhotra',
      'phone': '+91 91234 56789',
      'email': 'expansion@apexorganic.in',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOpportunities = _opportunities.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final company = (item['company'] ?? '').toString().toLowerCase();
      final title = (item['title'] ?? '').toString().toLowerCase();
      final location = (item['location'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();
      final pincode = (item['pincode'] ?? '').toString().toLowerCase();
      return company.contains(query) ||
          title.contains(query) ||
          location.contains(query) ||
          type.contains(query) ||
          pincode.contains(query);
    }).toList();

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
                        _searchQuery = val.trim();
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

                // Opportunities List
                Expanded(
                  child: filteredOpportunities.isEmpty
                      ? Center(
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
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredOpportunities.length,
                          itemBuilder: (context, index) {
                            final item = filteredOpportunities[index];
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
                                          item['type'],
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0B4F4A),
                                          ),
                                        ),
                                      ),
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
                                            item['location'],
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
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    item['company'],
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
                                        item['investment'],
                                      ),
                                      SizedBox(width: 8.w),
                                      _infoBadge(
                                        Icons.aspect_ratio,
                                        _isHindi ? 'क्षेत्र' : 'Area',
                                        item['area'],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      _infoBadge(
                                        Icons.trending_up,
                                        _isHindi ? 'रिटर्न' : 'Returns',
                                        item['returns'],
                                      ),
                                      SizedBox(width: 8.w),
                                      _infoBadge(
                                        Icons.pin_drop,
                                        _isHindi ? 'पिनकोड' : 'Pincode',
                                        item['pincode'],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    item['description'],
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.black54,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

  void _showContactDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          item['company'],
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
                          '${item['contactPerson']}',
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
                          '${item['phone']}',
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
                          '${item['email']}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
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
