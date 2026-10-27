import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/LoginScreen/WaitingParentApprovalScreen.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/SettingScreen/font_scale_provider.dart';
import 'package:track_loved/core/Utils/key.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("userdata");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _arePermissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDevicePermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDevicePermissions();
    }
  }

  Future<void> _checkDevicePermissions() async {
    final locationGranted = await Permission.location.isGranted;
    final contactsGranted = await Permission.contacts.isGranted;
    if (mounted) {
      setState(() {
        _arePermissionsGranted = locationGranted && contactsGranted;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.isBoxOpen("userdata") ? Hive.box("userdata") : null;
    var token = box?.get("token");
    var role = box?.get("role");
    var isParentConsentApproved = box?.get("isParentConsentApproved");
    var childPhone = box?.get("phone")?.toString() ?? '';
    var parentPhone = box?.get("parentPhone")?.toString();
    var isProfileComplete = box?.get("isProfileComplete");
    log("isProfileComplete :- $isProfileComplete");
    log("role :- $role, isParentConsentApproved :- $isParentConsentApproved");
    log("Device permissions granted: $_arePermissionsGranted");

    Widget homeScreen;
    if (_isLoading) {
      homeScreen = const Scaffold(
        backgroundColor: Color(0xFF0F3D38),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC5A038)),
        ),
      );
    } else if (role == 'child' && isParentConsentApproved != true) {
      homeScreen = WaitingParentApprovalScreen(
        childPhone: childPhone,
        parentPhone: parentPhone,
      );
    } else if (token == null) {
      homeScreen = const LoginScreen();
    } else if (!_arePermissionsGranted) {
      homeScreen = const RegistrationConsentScreen();
    } else if (isProfileComplete == false) {
      homeScreen = const ProfileScreen();
    } else {
      homeScreen = const DynamicDashboardScreen();
    }

    return ScreenUtilInit(
      designSize: Size(440, 855),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return AnnotatedRegion(
          value: const SystemUiOverlayStyle(
            // statusBarColor: Color(0xFFF3F3F3),
            // statusBarIconBrightness: Brightness.dark,
            // statusBarBrightness: Brightness.light,
          ),
          child: SafeArea(
            top: false,
            child: Consumer(
              builder: (context, ref, _) {
                final fontScale = ref.watch(fontScaleProvider);
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  navigatorKey: navigatorKey,
                  scaffoldMessengerKey: snackBarKey,
                  title: 'Flutter Demo',
                  home: homeScreen,
                  builder: (context, materialChild) {
                    final mediaQueryData = MediaQuery.of(context);
                    return MediaQuery(
                      data: mediaQueryData.copyWith(
                        textScaler: TextScaler.linear(fontScale),
                      ),
                      child: materialChild ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}




//  post job opportunites form fill karne ke bad manage my posting me job postings me show hoga
//  or jab post business opportunites form fill karta hia to manage my posting me business expansions me show hoga ok 
//  or explorer business opportunites me se koi use apply ya share profile kar deta hai to to iski data manage my application me show hota hia ok 