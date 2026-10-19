import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/LiveLocationMapScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';
import 'package:track_loved/core/Utils/AddressText.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchLovedOnesScreen extends ConsumerStatefulWidget {
  const SearchLovedOnesScreen({super.key});

  @override
  ConsumerState<SearchLovedOnesScreen> createState() =>
      _SearchLovedOnesScreenState();
}

class _SearchLovedOnesScreenState extends ConsumerState<SearchLovedOnesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  bool _isHindi = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  List<LocationSharingUser> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLocationSharing();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationSharing({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.getLocationSharingReceived();

      if (!mounted) return;

      final fetchedUsers = response.data?.users ?? [];

      setState(() {
        _users = List<LocationSharingUser>.from(fetchedUsers);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_users.isEmpty) {
          _errorMessage = e.toString();
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchLocationSharing(isRefresh: true);
  }

  // Static client-side search filtering
  List<LocationSharingUser> get _filteredLovedOnes {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((u) {
      final name = (u.name ?? '').toLowerCase();
      return name.contains(query);
    }).toList();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFF8E24AA),
      const Color(0xFFE91E63),
      const Color(0xFF00897B),
      const Color(0xFFFB8C00),
      const Color(0xFF3949AB),
    ];
    if (name.isEmpty) return colors[0];
    final code = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return colors[code % colors.length];
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return _isHindi ? 'उपलब्ध नहीं' : 'Not available';
    final local = date.toLocal();
    final timeStr =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    return '$dateStr $timeStr';
  }

  Future<void> _openMapWithCoordinates(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'स्थान निर्देशांक उपलब्ध नहीं हैं'
                : 'Location coordinates not available',
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isHindi ? 'मानचित्र नहीं खोला जा सका' : 'Could not launch map',
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi ? 'त्रुटि उत्पन्न हुई' : 'Error opening map',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        );
      }
    }
  }

  // Function to send help alert to all connected members
  void _sendHelpAlertToMembers() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            _isHindi ? 'मदद की चेतावनी भेजें' : 'Send Help Alert',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _isHindi
                ? 'क्या आप सुनिश्चित हैं कि आप अपने सभी जुड़े हुए सदस्यों को यह संदेश भेजना चाहते हैं कि आपको मदद की आवश्यकता है?'
                : 'Are you sure you want to notify all connected members that you need help?',
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _isHindi ? 'रद्द करें' : 'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B4F4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isHindi
                          ? 'सभी जुड़े हुए सदस्यों को मदद का संदेश भेज दिया गया है!'
                          : 'Help alert sent to all connected members!',
                      style: TextStyle(fontSize: 13.5.sp),
                    ),
                    backgroundColor: const Color(0xFF0B4F4A),
                  ),
                );
              },
              child: Text(
                _isHindi ? 'हाँ, भेजें' : 'Yes, Send',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLocationDetails(LocationSharingUser user) {
    final name = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!
        : (_isHindi ? 'अनाम मित्र' : 'Unknown Friend');
    final lat = user.latitude;
    final lng = user.longitude;
    final hasCoordinates = lat != null && lng != null;
    final canViewMap = user.access != false && hasCoordinates;
    final coordinatesText = hasCoordinates
        ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
        : (_isHindi ? 'स्थान उपलब्ध नहीं' : 'Location not available');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor:
                            (user.profileImage != null &&
                                user.profileImage!.isNotEmpty)
                            ? Colors.transparent
                            : _getAvatarColor(name),
                        backgroundImage:
                            (user.profileImage != null &&
                                user.profileImage!.isNotEmpty)
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child:
                            (user.profileImage == null ||
                                user.profileImage!.isEmpty)
                            ? Text(
                                _getInitials(name),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.sp,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            AddressText(
                              latitude: lat,
                              longitude: lng,
                              isHindi: _isHindi,
                              unavailableText: coordinatesText,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 22.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FB),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFDCDFE4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 16.sp,
                              color: const Color(0xFF0B4F4A),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _isHindi
                                    ? 'सटीक लाइव स्थान'
                                    : 'Precise Live Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        if (hasCoordinates) ...[
                          AddressText(
                            latitude: lat,
                            longitude: lng,
                            isHindi: _isHindi,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6.h),
                        ],
                        Text(
                          _isHindi
                              ? 'अंतिम अपडेट: ${_formatDateTime(user.updatedAt)}'
                              : 'Last updated: ${_formatDateTime(user.updatedAt)}',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4F4A),
                        disabledBackgroundColor: const Color(0xFFB0BEC5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      icon: Icon(Icons.map, color: Colors.white, size: 20.sp),
                      label: Text(
                        _isHindi
                            ? 'मानचित्र पर स्थान देखें'
                            : 'View Location on Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5.sp,
                        ),
                      ),
                      onPressed: !canViewMap
                          ? null
                          : () async {
                              final screenContext = this.context;
                              Navigator.pop(context);
                              await Navigator.push(
                                screenContext,
                                MaterialPageRoute(
                                  builder: (_) => LiveLocationMapScreen(
                                    user: user,
                                    isHindi: _isHindi,
                                  ),
                                ),
                              );
                              // Back from the map (e.g. sharing was turned off):
                              // reload the list from the API.
                              if (mounted)
                                _fetchLocationSharing(isRefresh: true);
                            },
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLovedOnes = _filteredLovedOnes;

    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),

      // Floating Action Button for Help Alert
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendHelpAlertToMembers,
        backgroundColor: Colors.red.shade700,
        icon: Icon(Icons.sos, color: Colors.white, size: 22.sp),
        label: Text(
          _isHindi ? 'मदद चाहिए' : 'Need Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),

      appBar: AppBarScreen(
        titleEn: 'Track Loved Ones',
        titleHi: 'प्रियजनों की खोज करें',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
        onNotificationPressed: () {},
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi
                      ? 'प्रियजनों का लाइव स्थान'
                      : 'Live Location of\nLoved Ones',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 14.h),

                // Search Bar (Static Filtering)
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  style: TextStyle(fontSize: 17.sp, color: Colors.black87),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 12.w,
                    ),
                    hintText: _isHindi ? 'नाम से खोजें' : 'Search by name',
                    hintStyle: TextStyle(
                      color: Colors.black45,
                      fontSize: 15.sp,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.black45,
                      size: 20.sp,
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _errorMessage != null && _users.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48.sp,
                                  color: Colors.white60,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _errorMessage != null
                                      ? _errorMessage!
                                      : (_isHindi
                                            ? 'कुछ गलत हो गया। कृपया फिर से प्रयास करें।'
                                            : 'Something went wrong. Please try again.'),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B4F4A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  onPressed: () => _fetchLocationSharing(),
                                  child: Text(
                                    _isHindi ? 'पुनः प्रयास करें' : 'Retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredLovedOnes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_outlined,
                                  size: 54.sp,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _isHindi
                                      ? 'कोई प्रियजन नहीं मिला'
                                      : 'No loved ones found',
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
                      : RefreshIndicator(
                          color: Colors.white,
                          backgroundColor: const Color(0xFF0B4F4A),
                          onRefresh: _handleRefresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: EdgeInsets.only(bottom: 80.h),
                            itemCount: filteredLovedOnes.length,
                            itemBuilder: (context, index) {
                              return _buildLovedOneCard(
                                filteredLovedOnes[index],
                              );
                            },
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

  Widget _buildLovedOneCard(LocationSharingUser user) {
    final name = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!
        : (_isHindi ? 'अनाम मित्र' : 'Unknown Friend');
    final lat = user.latitude;
    final lng = user.longitude;
    final hasCoordinates = lat != null && lng != null;
    final locationText = hasCoordinates
        ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
        : (_isHindi ? 'स्थान उपलब्ध नहीं' : 'Location not available');
    // Server says whether this friend currently lets us see their location.
    final isActive = user.access != false;
    final statusColor = isActive
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDCDFE4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor:
                (user.profileImage != null && user.profileImage!.isNotEmpty)
                ? Colors.transparent
                : _getAvatarColor(name),
            backgroundImage:
                (user.profileImage != null && user.profileImage!.isNotEmpty)
                ? NetworkImage(user.profileImage!)
                : null,
            child: (user.profileImage == null || user.profileImage!.isEmpty)
                ? Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                AddressText(
                  latitude: lat,
                  longitude: lng,
                  isHindi: _isHindi,
                  unavailableText: locationText,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8.sp, color: statusColor),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        isActive
                            ? (_isHindi
                                  ? 'स्थान सक्रिय (लाइव)'
                                  : 'Location Active (Live)')
                            : (_isHindi
                                  ? 'स्थान निष्क्रिय'
                                  : 'Location Inactive'),
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.location_on,
              color: const Color(0xFF0B4F4A),
              size: 24.sp,
            ),
            onPressed: () => _showLocationDetails(user),
          ),
        ],
      ),
    );
  }
}
