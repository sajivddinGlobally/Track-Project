import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/NetworkRequestScreen/Provider/NetworkRequestProvider.dart';
import 'package:track_loved/DrawerScreen/SearchLovedOnseScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class NetworkingRequestScreen extends ConsumerStatefulWidget {
  const NetworkingRequestScreen({super.key});

  @override
  ConsumerState<NetworkingRequestScreen> createState() =>
      NetworkingRequestScreenState();
}

class NetworkingRequestScreenState
    extends ConsumerState<NetworkingRequestScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isHindi = false;
  final Set<String> _acceptingIds = {};
  final Set<String> _rejectingIds = {};

  Future<void> _handleAccept(String id) async {
    setState(() {
      _acceptingIds.add(id);
    });
    try {
      final service = ref.read(authServiceProvider);
      final res = await service.acceptRequest(id: id);
      if (res.success == true) {
        ref.invalidate(networkRequestProvider);
        showSuccessSnackBar(
          _isHindi
              ? 'अनुरोध स्वीकार कर लिया गया'
              : 'Request accepted successfully',
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchLovedOnesScreen(),
            ),
          );
        }
      } else if (res.message != null && res.message!.isNotEmpty) {
        showErrorSnackBar(res.message!);
      }
    } catch (e) {
      log(e.toString());
      showErrorSnackBar(
        _isHindi
            ? 'अनुरोध स्वीकार करने में विफल रहा'
            : 'Failed to accept request',
      );
    } finally {
      if (mounted) {
        setState(() {
          _acceptingIds.remove(id);
        });
      }
    }
  }

  Future<void> _handleReject(String id) async {
    setState(() {
      _rejectingIds.add(id);
    });
    try {
      final service = ref.read(authServiceProvider);
      final res = await service.rejectRequest(id: id);
      if (res.success == true) {
        ref.invalidate(networkRequestProvider);
        showSuccessSnackBar(
          _isHindi ? 'अनुरोध अस्वीकार कर दिया गया' : 'Request rejected',
        );
      } else if (res.message != null && res.message!.isNotEmpty) {
        showErrorSnackBar(res.message!);
      }
    } catch (e) {
      log(e.toString());
      showErrorSnackBar(
        _isHindi
            ? 'अनुरोध अस्वीकार करने में विफल रहा'
            : 'Failed to reject request',
      );
    } finally {
      if (mounted) {
        setState(() {
          _rejectingIds.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkRequest = ref.watch(networkRequestProvider);

    return Scaffold(
      drawer: AppDrawer(isHindi: _isHindi),
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      appBar: AppBarScreen(
        titleEn: 'Networking requests',
        titleHi: 'नेटवर्किंग अनुरोध',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
      ),

      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF0B4F4A),
        displacement: 50.h,
        onRefresh: () async {
          ref.invalidate(networkRequestProvider);
          await ref.read(networkRequestProvider.future);
        },
        child: networkRequest.when(
          data: (data) {
            final requests = data.data?.requests ?? [];

            if (requests.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: _buildEmptyState(),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isHindi ? 'आने वाले अनुरोध' : 'Incoming Requests',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B4F4A),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                ...requests.map((item) {
                  final requestId = item.id ?? '';
                  final isAccepting = _acceptingIds.contains(requestId);
                  final isRejecting = _rejectingIds.contains(requestId);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildIncomingRequestCard(
                      name: item.senderId?.name ?? '',
                      city: item.senderId?.city ?? '',
                      state: item.senderId?.state ?? '',
                      country: item.senderId?.country ?? '',
                      id: requestId,
                      isAccepting: isAccepting,
                      isRejecting: isRejecting,
                      currentAddress: item.senderId?.currentAddress ?? '',
                      pin: item.senderId?.pincode ?? "",
                    ),
                  );
                }),
              ],
            );
          },
          error: (error, stackTrace) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Center(
                    child: Text(
                      _isHindi
                          ? 'डेटा लोड करने में त्रुटि आई'
                          : 'Error loading data',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86.w,
              height: 86.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0B4F4A).withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF136862), width: 1.5),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 44.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              _isHindi ? 'कोई अनुरोध नहीं है' : 'No Connection Requests',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _isHindi
                  ? 'वर्तमान में आपके पास कोई नया कनेक्शन अनुरोध लंबित नहीं है।'
                  : 'You currently have no pending connection requests.',
              style: TextStyle(
                fontSize: 13.5.sp,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestCard({
    required String name,
    required String city,
    required String state,
    required String country,
    required String id,
    required bool isAccepting,
    required bool isRejecting,
    required String currentAddress,
    required String pin,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDCDFE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFF0B4F4A),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.redAccent, size: 16.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  "$currentAddress $city $state $country $pin",
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAccepting || isRejecting
                      ? null
                      : () => _handleAccept(id),
                  icon: isAccepting
                      ? const SizedBox.shrink()
                      : Icon(Icons.check, size: 16.sp, color: Colors.white),
                  label: isAccepting
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isHindi ? 'स्वीकार करें' : 'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    disabledBackgroundColor: const Color(
                      0xFF2E7D32,
                    ).withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isAccepting || isRejecting
                      ? null
                      : () => _handleReject(id),
                  icon: isRejecting
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.close,
                          size: 16.sp,
                          color: const Color(0xFFD32F2F),
                        ),
                  label: isRejecting
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            color: Color(0xFFD32F2F),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isHindi ? 'अस्वीकार करें' : 'Reject',
                          style: TextStyle(
                            color: const Color(0xFFD32F2F),
                            fontSize: 13.5.sp,
                          ),
                        ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD32F2F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMemberCard({
    required String name,
    required String city,
    required String state,
    required String country,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDCDFE4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFF0B4F4A),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "$city $state $country",
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
