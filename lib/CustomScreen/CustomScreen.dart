import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/AddNetworkScreen/AddNetWorkScreen.dart';
import 'package:track_loved/DrawerScreen/ExploreBusinessScreen.dart';
import 'package:track_loved/DrawerScreen/Feedback_And_Google_Rating.dart';
import 'package:track_loved/DrawerScreen/KnowYourLawScreen.dart';
import 'package:track_loved/DrawerScreen/NetworkLocationpermissions.dart';
import 'package:track_loved/DrawerScreen/NetworkRequestScreen/NetworkingRequest.dart';
import 'package:track_loved/DrawerScreen/PostBusinessOpportunitiesScreen.dart';
import 'package:track_loved/DrawerScreen/PostJobOpprtunities.dart';
import 'package:track_loved/DrawerScreen/SearchLovedOnseScreen.dart';
import 'package:track_loved/HomeScreen/NotificationScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';

class AppDrawer extends StatelessWidget {
  final bool isHindi;
  const AppDrawer({super.key, required this.isHindi});

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF0B4F4A), size: 24.sp),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.5.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userdata');
    final name = box.get('name');
    final email = box.get('email');

    return Drawer(
      width: 320.w,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F3D38), Color(0xFF0B4F4A)],
              ),
            ),
            margin: EdgeInsets.zero,
            accountName: Text(
              name ?? "N/A",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              email ?? "N/A",
              style: GoogleFonts.outfit(
                fontSize: 14.5.sp,
                color: Colors.white70,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 32.r,
              backgroundColor: Colors.white,
              child: Text(
                (name != null && name.toString().trim().isNotEmpty)
                    ? name.toString().trim()[0].toUpperCase()
                    : "N/A",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0B4F4A),
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          _buildDrawerItem(
            icon: Icons.dashboard,
            title: isHindi ? 'डैशबोर्ड' : 'Dashboard',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          _buildDrawerItem(
            icon: Icons.person_add,
            title: isHindi ? 'नेटवर्क जोड़ें' : 'Add Network',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AddNetworkSearchScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.location_pin,
            title: isHindi
                ? 'नेटवर्क स्थान अनुमतियाँ'
                : 'Network Location Permissions',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => NetworkLocationPermissionsScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.people_alt,
            title: isHindi ? 'नेटवर्किंग अनुरोध' : 'Networking Requests',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const NetworkingRequestScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.favorite,
            title: isHindi ? 'प्रियजनों को ट्रैक करें' : 'Track Loved Ones',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => SearchLovedOnesScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.business_center,
            title: isHindi
                ? 'व्यापार के अवसर खोजें'
                : 'Explore Business Opportunities',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ExploreBusinessScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.add_business,
            title: isHindi
                ? 'व्यापार के अवसर पोस्ट करें'
                : 'Post Business Opportunities',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostBusinessOpportunitiesScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.gavel,
            title: isHindi ? 'कानून जानें' : 'Know Your Law',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => LegalAwarenessApp()),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.post_add,
            title: isHindi
                ? 'नौकरी के अवसर पोस्ट करें'
                : 'Post Job Opportunities',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PostJobOpportunitiesScreen(),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.feedback,
            title: isHindi ? 'गूगल फीडबैक' : 'Google Feedback',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeedbackRatingScreen()),
              );
            },
          ),

          Divider(height: 16.h, thickness: 1.h, color: const Color(0xFFE2E8F0)),

          _buildDrawerItem(
            icon: Icons.settings,
            title: isHindi ? 'सेटिंग्स' : 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          _buildDrawerItem(
            icon: Icons.logout,
            title: isHindi ? 'लॉग आउट' : 'Logout',
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    title: Text(
                      isHindi ? 'साइन आउट' : 'Sign Out',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 19.sp,
                      ),
                    ),
                    content: Text(
                      isHindi
                          ? 'क्या आप वाकई साइन आउट करना चाहते हैं?'
                          : 'Are you sure you want to sign out?',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          isHindi ? 'नहीं' : 'No',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          var box = Hive.box("userdata");
                          await box.clear();

                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text(
                          isHindi ? 'हाँ' : 'Yes',
                          style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class AppBarScreen extends StatefulWidget implements PreferredSizeWidget {
  final String titleEn;
  final String titleHi;
  final bool isHindi;
  final ValueChanged<bool> onLanguageChanged;
  final VoidCallback? onNotificationPressed;
  final int notificationCount;

  const AppBarScreen({
    super.key,
    required this.titleEn,
    required this.titleHi,
    required this.isHindi,
    required this.onLanguageChanged,
    this.onNotificationPressed,
    this.notificationCount = 0,
  });

  @override
  State<AppBarScreen> createState() => _AppBarScreenState();

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}

class _AppBarScreenState extends State<AppBarScreen> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B4F4A),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      toolbarHeight: 56.h,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Colors.white, size: 24.sp),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Text(
        widget.isHindi ? widget.titleHi : widget.titleEn,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 19.sp,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: ToggleButtons(
            constraints: BoxConstraints(minHeight: 28.h, minWidth: 42.w),
            borderRadius: BorderRadius.circular(16.r),
            selectedColor: Colors.white,
            fillColor: const Color(0xFF1565C0),
            color: Colors.white70,
            isSelected: [!widget.isHindi, widget.isHindi],
            onPressed: (int index) {
              widget.onLanguageChanged(index == 1);
            },
            children: [
              Text(
                'En',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'हिं',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 4.w),

        // Notification Badge Icon
        IconButton(
          icon: Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 24.sp,
          ),
          onPressed: () {
            if (widget.onNotificationPressed != null) {
              widget.onNotificationPressed!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationScreen(isHindi: widget.isHindi),
                ),
              );
            }
          },
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
