import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/LiveLocationMapScreen.dart';
import 'package:track_loved/DrawerScreen/NetworkLocationpermissions.dart';
import 'package:track_loved/MessageScreen/MessageScreen.dart';
import 'package:track_loved/core/AuthService/AuthService.dart';
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';
import 'package:track_loved/core/Network/ApiStateNetwork.dart';
import 'package:track_loved/core/Utils/key.dart';
import 'package:track_loved/core/Utils/preety.dio.dart';

import '../../DrawerScreen/NetworkRequestScreen/NetworkingRequest.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/HomeScreen/NotificationScreen.dart';

class FcmNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Notifier triggered when an expiring location alert push arrives,
  /// causing the Dashboard screen to auto-refresh its API data in real time.
  static final ValueNotifier<int> dashboardRefreshNotifier =
      ValueNotifier<int>(0);

  static void notifyDashboardRefresh() {
    dashboardRefreshNotifier.value++;
  }

  /// Tracks the userId of the chat currently opened by the user.
  /// When active, incoming chat notifications from this user are suppressed
  /// so that redundant banners do not pop up over the active chat screen.
  static String? currentActiveChatUserId;

  /// Channel 1: High priority / Siren sound for SOS & Emergency broadcast alerts
  static const AndroidNotificationChannel emergencyChannel =
      AndroidNotificationChannel(
        'emergency_channel_v3',
        'Emergency & SOS Alerts',
        description:
            'High priority siren alerts for emergency and SOS broadcasts',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('siren'),
        enableVibration: true,
        enableLights: true,
      );

  /// Channel 2: High priority sound for chat messages, friend requests, and reminders
  static const AndroidNotificationChannel defaultChannel =
      AndroidNotificationChannel(
        'default_channel_v3',
        'General Notifications',
        description: 'Notifications for chats, reminders, and friend requests',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('chime'),
        enableVibration: true,
        enableLights: true,
      );

  /// Initializes Android Notification Channels & local notification display settings
  static Future<void> initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              handleNotificationPayload(data);
            } catch (e) {
              log('[FCM] Error decoding notification response payload: $e');
            }
          }
        },
      );

      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        // Register all channels with raw audio resources
        await androidImpl.createNotificationChannel(emergencyChannel);
        await androidImpl.createNotificationChannel(defaultChannel);

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'emergency_channel',
            'Emergency & SOS Alerts',
            description: 'SOS and emergency alerts',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('siren'),
            enableVibration: true,
          ),
        );
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'default_channel',
            'General Notifications',
            description: 'Notifications for chats, reminders, and requests',
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('chime'),
            enableVibration: true,
          ),
        );

        log(
          '[FCM] Android Notification Channels registered successfully with high priority & sound',
        );
      }
    } catch (e) {
      log('[FCM] Failed to initialize local notifications: $e');
    }
  }

  static final Map<String, DateTime> _recentMessages = {};

  /// Checks if an incoming message is a duplicate within an 8-second window
  static bool _isDuplicateMessage(RemoteMessage message) {
    final now = DateTime.now();
    // Prune entries older than 8 seconds
    _recentMessages.removeWhere(
      (_, time) => now.difference(time).inSeconds > 8,
    );

    final msgId = message.messageId;
    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    final type = message.data['type']?.toString() ?? '';

    if (msgId != null &&
        msgId.isNotEmpty &&
        _recentMessages.containsKey(msgId)) {
      log('[FCM] Duplicate notification suppressed by messageId: $msgId');
      return true;
    }

    final contentKey = '$title|$body|$type';
    if (contentKey.length > 2 && _recentMessages.containsKey(contentKey)) {
      log('[FCM] Duplicate notification suppressed by content: $contentKey');
      return true;
    }

    if (msgId != null && msgId.isNotEmpty) {
      _recentMessages[msgId] = now;
    }
    if (contentKey.length > 2) {
      _recentMessages[contentKey] = now;
    }

    return false;
  }

  /// Displays foreground notification popup with proper channel sound & priority
  static Future<void> showForegroundNotification(RemoteMessage message) async {
    try {
      // Check if user is authenticated: if logged out, do not show any notification or sound
      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');
      final userToken = box.get('token')?.toString();
      if (userToken == null || userToken.isEmpty) {
        log(
          '[FCM] User is logged out, suppressing foreground notification & sound',
        );
        return;
      }

      if (_isDuplicateMessage(message)) {
        return;
      }

      final notification = message.notification;
      final data = message.data;
      final type = data['type']?.toString().toLowerCase();
      final screen = data['screen']?.toString().toLowerCase();

      // If user is currently inside MessageScreen chatting with this sender,
      // do not show the notification banner or alert sound (the chat bubble updates live via socket)
      if (type == 'chat' ||
          type == 'message' ||
          screen == 'chat' ||
          screen == 'messagescreen') {
        final senderId =
            data['senderId']?.toString() ??
            data['receiverId']?.toString() ??
            data['userId']?.toString() ??
            '';
        if (currentActiveChatUserId != null &&
            currentActiveChatUserId!.isNotEmpty &&
            senderId.isNotEmpty &&
            currentActiveChatUserId == senderId) {
          log(
            '[FCM] User is currently active in chat with $senderId - suppressing notification banner',
          );
          return;
        }
      }

      final title =
          notification?.title ??
          data['title']?.toString() ??
          'Track Loved Ones';
      final body = notification?.body ?? data['body']?.toString() ?? '';
      final channelId = data['channel']?.toString().toLowerCase();

      final isEmergency =
          type == 'sos_alert' ||
          channelId == 'emergency_channel' ||
          channelId == 'emergency_channel_v2' ||
          channelId == 'emergency_channel_v3';

      final isLocationReminder =
          type == 'location_reminder' ||
          title.toLowerCase().contains('location sharing active');

      final isExpiringAlert =
          type == 'location_permission_expiring' ||
          type == 'location_permission_expired' ||
          (type != null && type.contains('location_permission'));

      // If an expiring permission notification arrives, trigger real-time dashboard refresh
      if (isExpiringAlert) {
        notifyDashboardRefresh();
      }

      // If user took action in last 24 hours, completely suppress location reminder notification
      if (isLocationReminder) {
        final dismissedUntilStr =
            box.get('location_permission_alert_dismissed_until')?.toString();
        if (dismissedUntilStr != null && dismissedUntilStr.isNotEmpty) {
          final dismissedUntil = DateTime.tryParse(dismissedUntilStr);
          if (dismissedUntil != null &&
              DateTime.now().isBefore(dismissedUntil)) {
            log('[FCM] location_reminder suppressed: 24h action active until $dismissedUntil');
            return;
          }
        }
      }

      // Respect user sound & vibration settings saved in Hive
      bool soundEnabled =
          box.get('notif_sound_enabled', defaultValue: true) as bool;
      if (isLocationReminder) {
        // Mute loud ringtone player for location_reminder
        soundEnabled = false;
      }
      final bool vibrationEnabled =
          box.get('notif_vibration_enabled', defaultValue: true) as bool;
      final String selectedTone =
          box
              .get('notif_selected_tone', defaultValue: 'Default Chime')
              ?.toString() ??
          'Default Chime';
      final double soundVolume =
          (box.get('notif_sound_volume', defaultValue: 0.8) as num).toDouble();

      String soundFile = 'chime';
      if (isEmergency) {
        soundFile = 'siren';
      } else {
        switch (selectedTone) {
          case 'Gentle Bell':
            soundFile = 'bell';
            break;
          case 'Alert Pulse':
            soundFile = 'siren';
            break;
          case 'Radar Echo':
            soundFile = 'radar';
            break;
          case 'Subtle Beep':
            soundFile = 'beep';
            break;
          case 'Default Chime':
          default:
            soundFile = 'chime';
            break;
        }
      }

      // Emergency SOS gets an urgent repeating buzzer vibration pattern
      final Int64List? vibrationPattern = vibrationEnabled
          ? (isEmergency
                ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000])
                : Int64List.fromList([0, 250, 250, 250]))
          : null;

      final androidDetails = AndroidNotificationDetails(
        isEmergency ? emergencyChannel.id : defaultChannel.id,
        isEmergency ? emergencyChannel.name : defaultChannel.name,
        channelDescription: isEmergency
            ? emergencyChannel.description
            : defaultChannel.description,
        importance: isEmergency ? Importance.max : Importance.high,
        priority: isEmergency ? Priority.max : Priority.high,
        playSound: soundEnabled,
        sound: soundEnabled
            ? RawResourceAndroidNotificationSound(soundFile)
            : null,
        enableVibration: vibrationEnabled,
        vibrationPattern: vibrationPattern,
        fullScreenIntent: isEmergency,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Deterministic notification ID based on type or title to prevent duplicate stacked cards
      final int notifId = (type != null && type.isNotEmpty)
          ? (type.hashCode.abs() % 100000)
          : (title.hashCode.abs() % 100000);

      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(data),
      );

      // Play audio ringtone in foreground
      if (soundEnabled) {
        try {
          FlutterRingtonePlayer().play(
            fromAsset: "assets/sounds/$soundFile.wav",
            volume: soundVolume,
            asAlarm: isEmergency,
          );
        } catch (e) {
          log('[FCM] Error playing ringtone: $e');
        }
      }
    } catch (e) {
      log('[FCM] Error displaying foreground notification: $e');
    }
  }

  /// Handles background / terminated FCM message: plays tone & shows notification if needed
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      // Check if user is authenticated: if logged out, do not show any notification or sound
      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');
      final userToken = box.get('token')?.toString();
      if (userToken == null || userToken.isEmpty) {
        log(
          '[FCM] User is logged out, suppressing background message processing',
        );
        return;
      }

      if (_isDuplicateMessage(message)) {
        return;
      }

      log(
        '[FCM] Processing background message: ${message.messageId}, data: ${message.data}',
      );
      final data = message.data;
      final type = data['type']?.toString().toLowerCase();
      final channelId = data['channel']?.toString().toLowerCase();

      final bool isEmergency =
          type == 'sos_alert' ||
          channelId == 'emergency_channel' ||
          channelId == 'emergency_channel_v2' ||
          channelId == 'emergency_channel_v3';

      final isLocationReminder =
          type == 'location_reminder' ||
          (data['title']?.toString().toLowerCase().contains('location sharing active') ?? false);

      // Load user preferences in background isolate
      bool soundEnabled = true;
      String selectedTone = 'Default Chime';
      double soundVolume = 0.8;

      try {
        final box = Hive.isBoxOpen('userdata')
            ? Hive.box('userdata')
            : await Hive.openBox('userdata');

        if (isLocationReminder) {
          final dismissedUntilStr =
              box.get('location_permission_alert_dismissed_until')?.toString();
          if (dismissedUntilStr != null && dismissedUntilStr.isNotEmpty) {
            final dismissedUntil = DateTime.tryParse(dismissedUntilStr);
            if (dismissedUntil != null &&
                DateTime.now().isBefore(dismissedUntil)) {
              log('[FCM Background] location_reminder suppressed: 24h action active until $dismissedUntil');
              return;
            }
          }
        }

        soundEnabled =
            box.get('notif_sound_enabled', defaultValue: true) as bool;
        if (isLocationReminder) {
          soundEnabled = false;
        }
        selectedTone =
            box
                .get('notif_selected_tone', defaultValue: 'Default Chime')
                ?.toString() ??
            'Default Chime';
        soundVolume = (box.get('notif_sound_volume', defaultValue: 0.8) as num)
            .toDouble();
      } catch (e) {
        log('[FCM] Error reading Hive settings in background: $e');
      }

      String soundFile = 'chime';
      if (isEmergency) {
        soundFile = 'siren';
      } else {
        switch (selectedTone) {
          case 'Gentle Bell':
            soundFile = 'bell';
            break;
          case 'Alert Pulse':
            soundFile = 'siren';
            break;
          case 'Radar Echo':
            soundFile = 'radar';
            break;
          case 'Subtle Beep':
            soundFile = 'beep';
            break;
          case 'Default Chime':
          default:
            soundFile = 'chime';
            break;
        }
      }

      // 1. Play audio ringtone so user hears sound even if phone is locked/in background
      if (soundEnabled) {
        try {
          await FlutterRingtonePlayer().play(
            fromAsset: "assets/sounds/$soundFile.wav",
            volume: soundVolume,
            asAlarm: isEmergency,
          );
          log('[FCM] Background ringtone played successfully: $soundFile');
        } catch (e) {
          log('[FCM] Error playing ringtone in background: $e');
        }
      }

      // 2. If it is a data-only message (message.notification == null), system did not show banner,
      // so we must show a local notification so user sees the alert in notification tray.
      if (message.notification == null && data.isNotEmpty) {
        await initializeLocalNotifications();
        await showForegroundNotification(message);
      }
    } catch (e) {
      log('[FCM] Error in handleBackgroundMessage: $e');
    }
  }

  /// Subscribes to the broadcast emergency alerts topic
  static Future<void> subscribeToEmergencyTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic("emergency_alerts");
      log('[FCM] Subscribed to emergency_alerts topic');
    } catch (e) {
      log('[FCM] Failed to subscribe to emergency_alerts: $e');
    }
  }

  /// Unsubscribes from the emergency alerts topic (on logout)
  static Future<void> unsubscribeFromEmergencyTopic() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic("emergency_alerts");
      log('[FCM] Unsubscribed from emergency_alerts topic');
    } catch (e) {
      log('[FCM] Failed to unsubscribe from emergency_alerts: $e');
    }
  }

  /// Helper to get FCM token directly from FirebaseMessaging instance
  static Future<String?> getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final box = Hive.isBoxOpen("userdata")
            ? Hive.box("userdata")
            : await Hive.openBox("userdata");
        await box.put('fcm_token', token);
      }
      return token;
    } catch (e) {
      log('[FCM] Error fetching FCM token: $e');
      final box = Hive.isBoxOpen("userdata")
          ? Hive.box("userdata")
          : await Hive.openBox("userdata");
      return box.get('fcm_token')?.toString();
    }
  }

  /// Syncs FCM token to backend using PATCH /api/v1/auth/fcm-token
  /// When fcmToken is null, sends { "fcmToken": null } (used during logout).
  static Future<void> syncFcmToken(
    String? fcmToken, {
    Authservice? authService,
    bool force = false,
  }) async {
    try {
      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');

      final userToken = box.get('token')?.toString();
      if (userToken == null || userToken.isEmpty) {
        log('[FCM] User not authenticated, skipping FCM sync');
        return;
      }

      // If token not provided and not a forced logout, fallback to cached token or fetch from Firebase
      String? tokenToSend = fcmToken;
      if (tokenToSend == null && !force) {
        tokenToSend = box.get('fcm_token')?.toString();
        if (tokenToSend == null || tokenToSend.isEmpty) {
          tokenToSend = await FirebaseMessaging.instance.getToken();
          if (tokenToSend != null && tokenToSend.isNotEmpty) {
            await box.put('fcm_token', tokenToSend);
          }
        }
      }

      if (tokenToSend == null || tokenToSend.isEmpty) {
        log(
          '[FCM] Token is null or empty, skipping backend sync to avoid 400 Bad Request',
        );
        return;
      }

      final lastSyncedToken = box.get('synced_fcm_token')?.toString();
      if (!force && lastSyncedToken == tokenToSend) {
        log('[FCM] Token already synced with backend');
        return;
      }

      final dio = createDio();
      final service =
          authService ?? Authservice(ApiStateNetwork(dio), dio: dio);
      final res = await service.updateFcmTokenData(tokenToSend);
      log('[FCM] Token synced successfully with backend: $res');

      await box.put('synced_fcm_token', tokenToSend);
      await subscribeToEmergencyTopic();
    } catch (e) {
      log('[FCM] Failed to sync FCM token: $e');
    }
  }

  /// Logout cleanup: deletes Firebase device token, unsubscribes from topics, and clears FCM cache
  static Future<void> handleLogout({Authservice? authService}) async {
    try {
      log(
        '[FCM] Executing logout cleanup: deleting Firebase token & unsubscribing',
      );
      await unsubscribeFromEmergencyTopic();

      // Invalidate the FCM token on Firebase servers so Firebase stops delivering pushes to this device
      try {
        await FirebaseMessaging.instance.deleteToken();
        log(
          '[FCM] Firebase device token deleted successfully from Firebase servers',
        );
      } catch (e) {
        log('[FCM] Error deleting Firebase token: $e');
      }

      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');
      await box.delete('fcm_token');
      await box.delete('synced_fcm_token');

      // Sign out from Google Sign-In if active
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
          log('[GoogleSignIn] Signed out from Google successfully');
        }
      } catch (e) {
        log('[GoogleSignIn] Error signing out from Google: $e');
      }

      // Sign out from Firebase Auth if active
      try {
        await FirebaseAuth.instance.signOut();
        log('[FirebaseAuth] Signed out from Firebase successfully');
      } catch (e) {
        log('[FirebaseAuth] Error signing out from Firebase: $e');
      }

      log('[FCM] Logout cleanup finished successfully');
    } catch (e) {
      log('[FCM] Error in handleLogout: $e');
    }
  }

  /// Handles incoming notification data payload and redirects to the appropriate screen.
  /// Types supported:
  /// • type: "sos_alert" -> Live Location / SOS Alert Screen
  /// • type: "chat" -> Chat Screen (senderId provided)
  /// • type: "friend_request" -> Network / Friend Requests Screen
  /// • type: "location_reminder" -> Location Sharing Permissions Screen
  static void handleNotificationPayload(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return;
    log('[FCM] Handling notification payload: $data');

    final nav = navigatorKey.currentState;
    if (nav == null) {
      log('[FCM] NavigatorState not ready, scheduling routing for next frame');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationPayload(data);
      });
      return;
    }

    final type = data['type']?.toString().toLowerCase() ?? '';
    final screen = data['screen']?.toString().toLowerCase() ?? '';

    // Location permission expiring or expired -> Redirect to DashboardScreen & refresh data
    if (type == 'location_permission_expiring' ||
        type == 'location_permission_expired' ||
        type.contains('location_permission')) {
      notifyDashboardRefresh();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DynamicDashboardScreen()),
        (route) => false,
      );
    } else if (type == 'sos_alert' || screen == 'livelocation' || screen == 'sos') {
      final userId =
          data['senderId']?.toString() ?? data['userId']?.toString() ?? '';
      final name =
          data['senderName']?.toString() ??
          data['name']?.toString() ??
          'Emergency Alert';
      final user = LocationSharingUser(
        userId: userId,
        name: name,
        access: true,
      );
      nav.push(
        MaterialPageRoute(builder: (_) => LiveLocationMapScreen(user: user)),
      );
    } else if (type == 'chat' ||
        screen == 'chat' ||
        screen == 'messagescreen') {
      final senderId =
          data['senderId']?.toString() ?? data['receiverId']?.toString() ?? '';
      final senderName =
          data['senderName']?.toString() ?? data['name']?.toString() ?? 'Chat';
      final initials = senderName.isNotEmpty
          ? senderName[0].toUpperCase()
          : 'U';
      final profileImage = data['profileImage']?.toString() ?? '';

      nav.push(
        MaterialPageRoute(
          builder: (_) => MessageScreen(
            receiverId: senderId,
            name: senderName,
            initials: initials,
            profileImage: profileImage,
            isHindi: false,
          ),
        ),
      );
    } else if (type == 'friend_request' ||
        screen == 'addnetwork' ||
        screen == 'networkingrequest') {
      // nav.push(
      //   MaterialPageRoute(builder: (_) => const AddNetworkSearchScreen()),
      // );
      nav.push(
        MaterialPageRoute(builder: (_) => const NetworkingRequestScreen()),
      );
    } else if (type == 'location_reminder' ||
        screen == 'networklocationpermissions') {
      nav.push(
        MaterialPageRoute(
          builder: (_) => const NetworkLocationPermissionsScreen(),
        ),
      );
    } else {
      // Default: If notification has no specific screen, navigate to NotificationScreen
      log('[FCM] Generic / unhandled notification payload, navigating to NotificationScreen: $data');
      nav.push(
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    }
  }
}
