import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

const String kSocketBaseUrl = 'https://loveable-backend-5qi0.onrender.com';

class WaitingParentApprovalScreen extends StatefulWidget {
  final String childPhone;
  final String? parentPhone;
  final String? childName;

  const WaitingParentApprovalScreen({
    super.key,
    required this.childPhone,
    this.parentPhone,
    this.childName,
  });

  @override
  State<WaitingParentApprovalScreen> createState() =>
      _WaitingParentApprovalScreenState();
}

class _WaitingParentApprovalScreenState
    extends State<WaitingParentApprovalScreen>
    with SingleTickerProviderStateMixin {
  io.Socket? _socket;
  bool _isSocketConnected = false;
  bool _isApproved = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initSocket();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initSocket() {
    final cleanPhone = widget.childPhone.trim();
    if (cleanPhone.isEmpty) return;

    try {
      final socket = io.io(
        kSocketBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket = socket;

      socket.onConnect((_) {
        log('[ParentApprovalSocket] Connected: ${socket.id}');
        if (mounted) {
          setState(() {
            _isSocketConnected = true;
          });
        }
      });

      socket.onDisconnect((reason) {
        log('[ParentApprovalSocket] Disconnected: $reason');
        if (mounted) {
          setState(() {
            _isSocketConnected = false;
          });
        }
      });

      // Format potential phone event variants
      final eventsToListen = <String>{};
      eventsToListen.add('parent_consent_approved_$cleanPhone');

      if (cleanPhone.startsWith('+91')) {
        eventsToListen.add(
          'parent_consent_approved_${cleanPhone.replaceFirst('+91', '')}',
        );
      } else if (cleanPhone.length == 10) {
        eventsToListen.add('parent_consent_approved_+91$cleanPhone');
      }

      for (final event in eventsToListen) {
        log('[ParentApprovalSocket] Subscribing to event: $event');
        socket.on(event, (data) {
          log('[ParentApprovalSocket] Consent Approved Event Received: $data');
          _handleConsentApproved(data);
        });
      }

      socket.connect();
    } catch (e) {
      log('[ParentApprovalSocket] Setup error: $e');
    }
  }

  Future<void> _handleConsentApproved(dynamic data) async {
    if (_isApproved || !mounted) return;

    setState(() {
      _isApproved = true;
    });

    showSuccessSnackBar('Parent Approval Received! Account Unlocked 🎉');

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Check permissions and profile status from Hive
    final box = Hive.isBoxOpen('userdata')
        ? Hive.box('userdata')
        : await Hive.openBox('userdata');

    await box.put('isParentConsentApproved', true);

    final isProfileComplete = box.get('isProfileComplete') == true;
    final isLocationGranted = await Permission.location.isGranted;
    final isContactsGranted = await Permission.contacts.isGranted;

    if (!mounted) return;

    if (!isLocationGranted || !isContactsGranted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationConsentScreen(),
        ),
        (route) => false,
      );
      return;
    }

    if (isProfileComplete) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DynamicDashboardScreen()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
        (route) => false,
      );
    }
  }

  String _formatParentPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return "+91 XXXXX XXXXX";
    }
    final raw = phone.replaceAll(RegExp(r'\D'), '');
    if (raw.length >= 10) {
      final base10 = raw.substring(raw.length - 10);
      final start = base10.substring(0, 2); // Starting digits (e.g. 98)
      final end = base10.substring(
        base10.length - 4,
      ); // Ending digits (e.g. 3210)
      return "+91 ${start}XXXX$end";
    }
    if (raw.length >= 6) {
      final start = raw.substring(0, 2);
      final end = raw.substring(raw.length - 2);
      return "${start}XXXX$end";
    }
    return phone;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _socket?.clearListeners();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0F3D38);
    const accentGold = Color(0xFFD4AF37);
    const brightGreen = Color(0xFF00E676);

    final displayParentPhone = _formatParentPhone(widget.parentPhone);

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Parental Gate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated Radar / Shield Badge
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isApproved
                              ? brightGreen.withValues(alpha: 0.15)
                              : accentGold.withValues(alpha: 0.12),
                          border: Border.all(
                            color: _isApproved ? brightGreen : accentGold,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isApproved ? brightGreen : accentGold)
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isApproved
                              ? Icons.check_circle_outline_rounded
                              : Icons.hourglass_top_rounded,
                          size: 64.sp,
                          color: _isApproved ? brightGreen : accentGold,
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Title
                    Text(
                      _isApproved
                          ? "Consent Approved!"
                          : "Waiting for Parent Approval",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Description text with parent phone
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        "A consent link has been sent to your parent's phone ($displayParentPhone). Please ask your parent to approve the request.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.45,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // DPDP Act 2023 Compliance Info Box
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3D38).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: brightGreen.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: brightGreen,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'DPDP Act, 2023 Child Protection',
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: brightGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Under Section 9 of the DPDP Act, live location tracking cannot be activated on minors\' devices without verifiable parent/guardian consent. As soon as your parent opens the link and approves, this screen will auto-unlock instantly.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Live Socket Sync Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSocketConnected
                                ? brightGreen
                                : Colors.amber,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isSocketConnected
                                            ? brightGreen
                                            : Colors.amber)
                                        .withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _isApproved
                              ? 'Approval verified! Redirecting...'
                              : (_isSocketConnected
                                    ? 'Real-time approval listener active'
                                    : 'Connecting to server...'),
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    // Check Status Manually Button
                    // Container(
                    //   width: double.infinity,
                    //   height: 52.h,
                    //   decoration: BoxDecoration(
                    //     gradient: const LinearGradient(
                    //       colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                    //     ),
                    //     borderRadius: BorderRadius.circular(14.r),
                    //   ),
                    //   child: ElevatedButton(
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.transparent,
                    //       shadowColor: Colors.transparent,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(14.r),
                    //       ),
                    //     ),
                    //     onPressed: () {
                    //       showSuccessSnackBar(
                    //         'Still awaiting parent response. Please remind your parent to click the SMS link.',
                    //       );
                    //     },
                    //     child: Text(
                    //       "I'VE ASKED MY PARENT TO APPROVE",
                    //       style: TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 14.5.sp,
                    //         fontWeight: FontWeight.bold,
                    //         letterSpacing: 0.5,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 16.h),

                    // Return to Sign In Option
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Back to Sign In',
                        style: TextStyle(
                          color: const Color(0xFFD4AF37),
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
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
