import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class SystemPermissionsScreen extends StatefulWidget {
  final bool isHindi;

  const SystemPermissionsScreen({super.key, this.isHindi = false});

  @override
  State<SystemPermissionsScreen> createState() => _SystemPermissionsScreenState();
}

class _SystemPermissionsScreenState extends State<SystemPermissionsScreen> with WidgetsBindingObserver {
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _contactsStatus = PermissionStatus.denied;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final loc = await Permission.location.status;
    final contacts = await Permission.contacts.status;

    if (!mounted) return;
    setState(() {
      _locationStatus = loc;
      _contactsStatus = contacts;
      _isLoading = false;
    });
  }

  String _getStatusLabel(PermissionStatus status) {
    if (status.isGranted) {
      return widget.isHindi ? 'सक्रिय (ENABLED)' : 'ENABLED';
    } else if (status.isPermanentlyDenied) {
      return widget.isHindi ? 'स्थायी रूप से अस्वीकृत' : 'PERMANENTLY DENIED';
    } else if (status.isRestricted) {
      return widget.isHindi ? 'प्रतिबंधित (RESTRICTED)' : 'RESTRICTED';
    }
    return widget.isHindi ? 'अस्वीकृत / बंद' : 'DISABLED / NOT GRANTED';
  }

  Color _getStatusColor(PermissionStatus status) {
    if (status.isGranted) return const Color(0xFF00E676);
    if (status.isPermanentlyDenied) return Colors.redAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D38),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F3D38),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHindi ? 'डिवाइस हार्डवेयर अनुमतियां' : 'System Hardware Permissions',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        brightGold.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: brandGold.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phonelink_setup_rounded, color: brightGold, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            widget.isHindi
                                ? 'डिवाइस हार्डवेयर अनुमतियां 📱'
                                : 'Device Hardware Permissions 📱',
                            style: GoogleFonts.outfit(
                              color: brightGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.isHindi
                            ? 'यह पृष्ठ आपके डिवाइस-स्तरीय OS अनुमतियों की स्थिति प्रदर्शित करता है। DPDP अधिनियम के तहत, आपको इन्हें किसी भी समय रद्द करने की पूर्ण स्वायत्तता है।'
                            : 'This screen displays hardware OS-level parameters. Under the DPDP Act, 2023, you have full autonomy to revoke device permissions at any time via system settings.',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12.5.sp,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: const CircularProgressIndicator(color: brightGold),
                    ),
                  )
                else ...[
                  // Permission 1: GPS Location Access
                  _buildPermissionCard(
                    icon: Icons.location_on_rounded,
                    title: widget.isHindi ? 'जीपीएस लोकेशन एक्सेस (GPS Location)' : 'GPS Location Access',
                    status: _locationStatus,
                    purpose: widget.isHindi
                        ? 'उद्देश्य: केवल आपके द्वारा अधिकृत सर्कल सदस्यों को वास्तविक समय में आपके सटीक निर्देशांक प्रसारित करने के लिए।'
                        : 'Purpose: To broadcast real-time precise coordinates exclusively to your authorized circle.',
                    revokeInstruction: widget.isHindi
                        ? 'रद्द करने का तरीका: नीचे "ओपन सिस्टम सेटिंग्स" पर टैप करें -> Permissions -> Location -> "Don\'t Allow" चुनें।'
                        : 'How to Revoke: Tap below to open your OS Device Settings app -> Permissions -> Location -> Select "Don\'t Allow".',
                  ),
                  SizedBox(height: 16.h),

                  // Permission 2: Contacts / Address Book
                  _buildPermissionCard(
                    icon: Icons.contacts_rounded,
                    title: widget.isHindi
                        ? 'संपर्क / पता पुस्तिका (Contacts Access)'
                        : 'Contacts / Address Book Access',
                    status: _contactsStatus,
                    purpose: widget.isHindi
                        ? 'उद्देश्य: स्थानीय रूप से संपर्कों को लोड करने के लिए ताकि आप चुनिंदा संपर्कों को ट्रैकिंग अनुमति दे सकें (संपर्क सर्वर पर अपलोड नहीं होते)।'
                        : 'Purpose: Used to locally pull mobile records so you can selectively assign tracking paths (never uploaded to servers).',
                    revokeInstruction: widget.isHindi
                        ? 'रद्द करने का तरीका: नीचे "ओपन सिस्टम सेटिंग्स" पर टैप करें -> Permissions -> Contacts -> "Don\'t Allow" चुनें।'
                        : 'How to Revoke: Tap below to open your OS Device Settings app -> Permissions -> Contacts -> Select "Don\'t Allow".',
                  ),
                  SizedBox(height: 32.h),

                  // Open System OS Settings Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brightGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.settings_outlined, color: const Color(0xFF0F3D38), size: 20.sp),
                      label: Text(
                        widget.isHindi
                            ? '⚙️ सिस्टम OS सेटिंग्स पैनल खोलें'
                            : '⚙️ Open System OS Settings Panel',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F3D38),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      onPressed: () async {
                        await openAppSettings();
                      },
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required PermissionStatus status,
    required String purpose,
    required String revokeInstruction,
  }) {
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 0.8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            purpose,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: const Color(0xFFD4AF37), size: 15.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    revokeInstruction,
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      color: Colors.white60,
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
