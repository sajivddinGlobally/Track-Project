import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/AdultOnboardingScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/LoginScreen/WaitingParentApprovalScreen.dart';
import 'package:track_loved/LoginScreen/registerConsentScreen.dart';
import 'package:track_loved/ProfileScreen/ProfileScreen.dart';
import 'package:track_loved/SettingScreen/font_scale_provider.dart';
import 'package:track_loved/core/Utils/FcmNotificationService.dart';
import 'package:track_loved/core/Utils/key.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    log('[FCM] Handling background message: ${message.messageId}');
    await FcmNotificationService.handleBackgroundMessage(message);
  } catch (e) {
    log('[FCM] Error in background messaging handler: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("userdata");

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FcmNotificationService.initializeLocalNotifications();
    await FcmNotificationService.subscribeToEmergencyTopic();
    _initFcmNotifications();
  } catch (e) {
    log('[Firebase] Initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initFcmNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Fetch standard FCM Device Token
    try {
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        log('[FCM] Token acquired:--- $token');
        final box = Hive.isBoxOpen("userdata")
            ? Hive.box("userdata")
            : await Hive.openBox("userdata");
        await box.put('fcm_token', token);
        await FcmNotificationService.syncFcmToken(token);
      }
    } catch (e) {
      log('[FCM] getToken error: $e');
    }

    // Listen for token rotations
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      log('[FCM] Token refreshed: $newToken');
      final box = Hive.isBoxOpen("userdata")
          ? Hive.box("userdata")
          : await Hive.openBox("userdata");
      await box.put('fcm_token', newToken);
      await FcmNotificationService.syncFcmToken(newToken);
    });

    // Handle foreground message presentation & banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('[FCM] Foreground message received: ${message.notification?.title}');
      FcmNotificationService.showForegroundNotification(message);
    });

    // Handle notification click when app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[FCM] Notification opened app from background: ${message.data}');
      FcmNotificationService.handleNotificationPayload(message.data);
    });

    // Handle notification click when app was completely terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log(
        '[FCM] App launched from terminated state via notification: ${initialMessage.data}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmNotificationService.handleNotificationPayload(initialMessage.data);
      });
    }
  } catch (e) {
    log('[FCM] Error setting up FirebaseMessaging: $e');
  }
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
    var isPaymentPending =
        box?.get("isPaymentPending") == true ||
        (role == 'company' && box?.get("isCompanyPaymentCompleted") != true);
    var requiresAdultReconsent =
        box?.get("requiresAdultReconsent") == true ||
        role == 'adult_pending_consent';
    log("isProfileComplete :- $isProfileComplete");
    log(
      "role :- $role, isParentConsentApproved :- $isParentConsentApproved, requiresAdultReconsent :- $requiresAdultReconsent, isPaymentPending :- $isPaymentPending",
    );
    log("Device permissions granted: $_arePermissionsGranted");

    Widget homeScreen;
    if (_isLoading) {
      homeScreen = const Scaffold(
        backgroundColor: Color(0xFF0F3D38),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC5A038)),
        ),
      );
    } else if (token == null || isPaymentPending) {
      homeScreen = const LoginScreen();
    } else if (role == 'child' && isParentConsentApproved != true) {
      homeScreen = WaitingParentApprovalScreen(
        childPhone: childPhone,
        parentPhone: parentPhone,
      );
    } else if (requiresAdultReconsent) {
      homeScreen = const AdultOnboardingScreen();
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