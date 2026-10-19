import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/trackFriendModel.dart';

class NetworkLocationPermissionsScreen extends ConsumerStatefulWidget {
  const NetworkLocationPermissionsScreen({super.key});

  @override
  ConsumerState<NetworkLocationPermissionsScreen> createState() =>
      _NetworkLocationPermissionsScreenState();
}

class _NetworkLocationPermissionsScreenState
    extends ConsumerState<NetworkLocationPermissionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isHindi = false;
  bool _isLoading = true;
  final Set<String> _updatingIds = {};
  String? _errorMessage;
  String _searchQuery = '';
  List<FriendElement> _friends = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFriends();
    });
  }

  Future<void> _fetchFriends({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authService = ref.read(authServiceProvider);
      final query = _searchQuery.trim();
      final response = await authService.trackFriend(
        search: query.isNotEmpty ? query : null,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;

      final fetchedFriends = response.data?.friends ?? [];

      setState(() {
        _friends = List<FriendElement>.from(fetchedFriends);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, st) {
      log(st.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchFriends();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final activeCount = _friends
        .where((u) => u.sharingMyLocation == true)
        .length;

    // Filter list based on search query matching friend name locally as well
    final filteredFriends = _friends.where((item) {
      final name = item.friend?.name ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: "Network Location Permissions",
        titleHi: "नेटवर्क स्थान अनुमतियाँ",
        isHindi: _isHindi,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
        onNotificationPressed: () {},
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchFriends(isRefresh: true),
        color: const Color(0xFF0B4F4A),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title inside body
                  Text(
                    _isHindi
                        ? 'नेटवर्क स्थान\nअनुमतियाँ'
                        : 'Network Location\nPermissions',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 14.h),

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
                      onChanged: _onSearchChanged,
                      style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        hintText: _isHindi ? 'नाम खोजें' : 'Search Name',
                        hintStyle: TextStyle(
                          color: Colors.black45,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black45,
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
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // User Cards List or Loader
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : filteredFriends.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 80.h),
                              Center(
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
                                      _errorMessage != null
                                          ? _errorMessage!
                                          : (_isHindi
                                                ? 'कोई स्वीकृत कनेक्शन नहीं मिला'
                                                : 'No accepted connections found'),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14.sp,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredFriends.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(filteredFriends[index]);
                            },
                          ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isHindi ? 'सक्रिय कनेक्शन' : 'ACTIVE CONNECTIONS',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '$activeCount',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Save Permissions Button
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h, top: 4.h),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isHindi
                                    ? 'अनुमतियाँ सफलतापूर्वक सहेजी गईं!'
                                    : 'Permissions saved successfully!',
                                style: TextStyle(fontSize: 13.5.sp),
                              ),
                              backgroundColor: const Color(0xFF0B4F4A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4F4A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                        ),
                        child: Text(
                          _isHindi ? 'अनुमतियाँ सहेजें' : 'Save Permissions',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(FriendElement item) {
    final friend = item.friend;
    final name = friend?.name ?? 'Unknown';
    final profileImage = friend?.profileImage?.trim();
    final isShared = item.sharingMyLocation ?? false;
    final avatarColor = _getAvatarColor(name);

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
            radius: 22.r,
            backgroundColor: avatarColor,
            backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                ? NetworkImage(profileImage)
                : null,
            child: (profileImage == null || profileImage.isEmpty)
                ? Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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
                SizedBox(height: 2.h),
                Text(
                  isShared
                      ? (_isHindi
                            ? 'ट्रैक नेटवर्क पर स्थान साझा किया गया'
                            : 'Location shared on Track Network')
                      : (_isHindi
                            ? 'ट्रैक नेटवर्क पर स्थान छिपा हुआ है'
                            : 'Location hidden on Track Network'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isShared
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isShared,
              activeTrackColor: const Color(0xFF0B4F4A),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFB0BEC5),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              // Ignore taps while the previous request is still running.
              onChanged: _updatingIds.contains(friend?.id)
                  ? null
                  : (bool value) async {
                      final id = friend?.id;
                      if (id == null) return;
                      final previous = item.sharingMyLocation ?? false;
                      setState(() {
                        item.sharingMyLocation = value;
                        _updatingIds.add(id);
                      });
                      try {
                        await ref
                            .read(authServiceProvider)
                            .locationSharing(id: id, value: value);
                      } catch (_) {
                        // Server rejected it: put the switch back to the
                        // state the server still has.
                        if (mounted) {
                          setState(() => item.sharingMyLocation = previous);
                        }
                      } finally {
                        if (mounted) setState(() => _updatingIds.remove(id));
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
