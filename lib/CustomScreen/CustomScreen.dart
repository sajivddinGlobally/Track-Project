import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/AddNetworkScreen/AddNetWorkScreen.dart';
import 'package:track_loved/DrawerScreen/ExploreBusinessScreen.dart';
import 'package:track_loved/DrawerScreen/Feedback_And_Google_Rating.dart';
import 'package:track_loved/DrawerScreen/KnowYourLawScreen.dart';
import 'package:track_loved/DrawerScreen/ManageMyApplicationsScreen.dart';
import 'package:track_loved/DrawerScreen/ManageMyPostingsScreen.dart';
import 'package:track_loved/DrawerScreen/NetworkLocationpermissions.dart';
import 'package:track_loved/DrawerScreen/NetworkRequestScreen/NetworkingRequest.dart';
import 'package:track_loved/DrawerScreen/PostBusinessOpportunitiesScreen.dart';
import 'package:track_loved/DrawerScreen/PostJobOpprtunities.dart';
import 'package:track_loved/DrawerScreen/SearchLovedOnseScreen.dart';
import 'package:track_loved/HomeScreen/NotificationScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/LoginScreen/RegisterScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/SettingScreen/SettingScreen.dart';
import 'package:track_loved/core/Utils/FcmNotificationService.dart';

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

  void _navigateToScreen(BuildContext context, Widget targetScreen) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (context) => targetScreen),
      (route) => route.isFirst,
    );
  }

  void _showCompanyRegistrationRequiredDialog(
    BuildContext context, {
    required bool isJobPosting,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6C567).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_center,
                  color: const Color(0xFF002E29),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  isHindi ? 'कंपनी खाता आवश्यक' : 'Company Account Required',
                  style: GoogleFonts.outfit(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF002E29),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isHindi
                ? (isJobPosting
                    ? 'नौकरी के अवसर पोस्ट करने के लिए आपको साइन अप स्क्रीन पर कंपनी के रूप में रजिस्टर करना होगा और अपनी कंपनी प्रोफ़ाइल व KYC पूरा करना होगा।'
                    : 'व्यापार के अवसर पोस्ट करने के लिए आपको साइन अप स्क्रीन पर कंपनी के रूप में रजिस्टर करना होगा और अपनी कंपनी प्रोफ़ाइल व KYC पूरा करना होगा।')
                : (isJobPosting
                    ? 'To post job opportunities, please register as a Company on the Sign Up screen and complete your Company Profile & Corporate KYC.'
                    : 'To post business opportunities, please register as a Company on the Sign Up screen and complete your Company Profile & Corporate KYC.'),
            style: GoogleFonts.outfit(
              fontSize: 14.5.sp,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                isHindi ? 'रद्द करें' : 'Cancel',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002E29),
                foregroundColor: const Color(0xFFE6C567),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) =>
                        const SignUpScreen(initialAccountType: 'company'),
                  ),
                );
              },
              child: Text(
                isHindi ? 'कंपनी रजिस्टर करें' : 'Sign Up as Company',
                style: GoogleFonts.outfit(
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

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userdata');
    final name = box.get('name');
    final email = box.get('email');
    final profileImage = box.get('profileImage')?.toString();
    final role = box.get('role');

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
            otherAccountsPictures: [
              Tooltip(
                message: isHindi ? 'प्रोफ़ाइल संपादित करें' : 'Edit Profile',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _navigateToScreen(context, const ProfileScreen());
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ],
            currentAccountPicture: GestureDetector(
              onTap: () {
                _navigateToScreen(context, const ProfileScreen());
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFFFD54F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32.r,
                      backgroundColor: const Color(0xFF0F3D38),
                      backgroundImage:
                          (profileImage != null &&
                              profileImage.trim().isNotEmpty)
                          ? NetworkImage(profileImage.trim())
                          : null,
                      child:
                          (profileImage == null || profileImage.trim().isEmpty)
                          ? Text(
                              (name != null &&
                                      name.toString().trim().isNotEmpty)
                                  ? name.toString().trim()[0].toUpperCase()
                                  : "N/A",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 22.sp,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8.h),

          _buildDrawerItem(
            icon: Icons.dashboard,
            title: isHindi ? 'डैशबोर्ड' : 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),

          if (role == 'user' || role == 'child')
            _buildDrawerItem(
              icon: Icons.person_add,
              title: isHindi ? 'नेटवर्क जोड़ें' : 'Add Network',
              onTap: () {
                _navigateToScreen(context, const AddNetworkSearchScreen());
              },
            ),

          if (role == 'user' || role == 'child')
            _buildDrawerItem(
              icon: Icons.location_pin,
              title: isHindi
                  ? 'नेटवर्क स्थान अनुमतियाँ'
                  : 'Network Location Permissions',
              onTap: () {
                _navigateToScreen(context, NetworkLocationPermissionsScreen());
              },
            ),
          if (role == 'user' || role == 'child')
            _buildDrawerItem(
              icon: Icons.people_alt,
              title: isHindi ? 'नेटवर्किंग अनुरोध' : 'Networking Requests',
              onTap: () {
                _navigateToScreen(context, const NetworkingRequestScreen());
              },
            ),
          if (role == 'user' || role == 'child')
            _buildDrawerItem(
              icon: Icons.favorite,
              title: isHindi ? 'प्रियजनों को ट्रैक करें' : 'Track Loved Ones',
              onTap: () {
                _navigateToScreen(context, SearchLovedOnesScreen());
              },
            ),
          if (role == "user" || role == "company")
            _buildDrawerItem(
              icon: Icons.business_center,
              title: isHindi
                  ? 'व्यापार के अवसर खोजें'
                  : 'Explore Business Opportunities',
              onTap: () {
                _navigateToScreen(context, ExploreBusinessScreen());
              },
            ),

          if (role == "user")
            _buildDrawerItem(
              icon: Icons.assignment_turned_in_outlined,
              title: isHindi
                  ? 'मेरे आवेदन (गोपनीयता डैशबोर्ड)'
                  : 'Manage My Applications',
              onTap: () {
                _navigateToScreen(
                  context,
                  ManageMyApplicationsScreen(initialHindi: isHindi),
                );
              },
            ),

          if (role != "child")
            _buildDrawerItem(
              icon: Icons.add_business,
              title: isHindi
                  ? 'व्यापार के अवसर पोस्ट करें'
                  : 'Post Business Opportunities',
              onTap: () {
                if (role == "company") {
                  _navigateToScreen(
                    context,
                    const PostBusinessOpportunitiesScreen(),
                  );
                } else {
                  _showCompanyRegistrationRequiredDialog(
                    context,
                    isJobPosting: false,
                  );
                }
              },
            ),

          if (role != "company")
            _buildDrawerItem(
              icon: Icons.gavel,
              title: isHindi ? 'कानून जानें' : 'Know Your Law',
              onTap: () {
                _navigateToScreen(context, LegalAwarenessApp());
              },
            ),

          if (role != "child")
            _buildDrawerItem(
              icon: Icons.post_add,
              title: isHindi
                  ? 'नौकरी के अवसर पोस्ट करें'
                  : 'Post Job Opportunities',
              onTap: () {
                if (role == "company") {
                  _navigateToScreen(
                    context,
                    const PostJobOpportunitiesScreen(),
                  );
                } else {
                  _showCompanyRegistrationRequiredDialog(
                    context,
                    isJobPosting: true,
                  );
                }
              },
            ),

          if (role == "company")
            _buildDrawerItem(
              icon: Icons.admin_panel_settings_outlined,
              title: isHindi
                  ? 'प्रकाशित अवसर प्रबंधित करें'
                  : 'Manage My Postings',
              onTap: () {
                _navigateToScreen(
                  context,
                  ManageMyPostingsScreen(initialHindi: isHindi),
                );
              },
            ),

          _buildDrawerItem(
            icon: Icons.feedback_outlined,
            title: isHindi ? 'फीडबैक एवं बग रिपोर्ट' : 'Feedback & Bug Report',
            onTap: () {
              _navigateToScreen(
                context,
                FeedbackRatingScreen(isHindi: isHindi),
              );
            },
          ),

          Divider(height: 16.h, thickness: 1.h, color: const Color(0xFFE2E8F0)),

          _buildDrawerItem(
            icon: Icons.settings,
            title: isHindi ? 'सेटिंग्स' : 'Settings',
            onTap: () {
              _navigateToScreen(context, SettingScreen(isHindi: isHindi));
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
                          // Immediately navigate to LoginScreen, replacing dialog and all screens
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            CupertinoPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );

                          // Notify backend that user is logging out (fcmToken: null) & unsubscribe
                          await FcmNotificationService.handleLogout();

                          final box = Hive.isBoxOpen("userdata")
                              ? Hive.box("userdata")
                              : await Hive.openBox("userdata");
                          await box.clear();
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
