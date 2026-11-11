import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/AddNetworkScreen/AddNetWorkScreen.dart';
import 'package:track_loved/DrawerScreen/LiveLocationMapScreen.dart';
import 'package:track_loved/DrawerScreen/NetworkLocationpermissions.dart';
import 'package:track_loved/MessageScreen/MessageScreen.dart';
import 'package:track_loved/core/AuthService/AuthService.dart';
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';
import 'package:track_loved/core/Network/ApiStateNetwork.dart';
import 'package:track_loved/core/Utils/key.dart';
import 'package:track_loved/core/Utils/preety.dio.dart';

class FcmNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Channel 1: High priority / Siren sound for SOS & Emergency broadcast alerts
  static const AndroidNotificationChannel emergencyChannel =
      AndroidNotificationChannel(
        'emergency_channel',
        'Emergency & SOS Alerts',
        description:
            'High priority siren alerts for emergency and SOS broadcasts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  /// Channel 2: Default sound for chat messages, friend requests, and reminders
  static const AndroidNotificationChannel defaultChannel =
      AndroidNotificationChannel(
        'default_channel',
        'General Notifications',
        description:
            'Default notifications for chats, reminders, and friend requests',
        importance: Importance.defaultImportance,
        playSound: true,
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
        await androidImpl.createNotificationChannel(emergencyChannel);
        await androidImpl.createNotificationChannel(defaultChannel);
        log('[FCM] Android Notification Channels registered successfully');
      }
    } catch (e) {
      log('[FCM] Failed to initialize local notifications: $e');
    }
  }

  /// Displays foreground notification popup with proper channel sound & priority
  static Future<void> showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      final title =
          notification?.title ??
          data['title']?.toString() ??
          'Track Loved Ones';
      final body = notification?.body ?? data['body']?.toString() ?? '';
      final type = data['type']?.toString().toLowerCase();
      final channelId = data['channel']?.toString().toLowerCase();

      final isEmergency =
          type == 'sos_alert' || channelId == 'emergency_channel';

      final androidDetails = AndroidNotificationDetails(
        isEmergency ? emergencyChannel.id : defaultChannel.id,
        isEmergency ? emergencyChannel.name : defaultChannel.name,
        channelDescription: isEmergency
            ? emergencyChannel.description
            : defaultChannel.description,
        importance: isEmergency ? Importance.max : Importance.defaultImportance,
        priority: isEmergency ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      log('[FCM] Error displaying foreground notification: $e');
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

      final lastSyncedToken = box.get('synced_fcm_token')?.toString();
      if (!force && lastSyncedToken == tokenToSend && tokenToSend != null) {
        log('[FCM] Token already synced with backend');
        return;
      }

      final dio = createDio();
      final service =
          authService ?? Authservice(ApiStateNetwork(dio), dio: dio);
      final res = await service.updateFcmTokenData(tokenToSend);
      log('[FCM] Token synced successfully with backend: $res');

      if (tokenToSend != null && tokenToSend.isNotEmpty) {
        await box.put('synced_fcm_token', tokenToSend);
        await subscribeToEmergencyTopic();
      } else {
        await box.delete('synced_fcm_token');
        await unsubscribeFromEmergencyTopic();
      }
    } catch (e) {
      log('[FCM] Failed to sync FCM token: $e');
    }
  }

  /// Logout cleanup: sends fcmToken null to backend and unsubscribes from topics
  static Future<void> handleLogout({Authservice? authService}) async {
    try {
      log('[FCM] Executing logout cleanup: setting fcmToken to null');
      await syncFcmToken(null, authService: authService, force: true);
      await unsubscribeFromEmergencyTopic();
      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');
      await box.delete('synced_fcm_token');
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

    if (type == 'sos_alert' || screen == 'livelocation' || screen == 'sos') {
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
      nav.push(
        MaterialPageRoute(builder: (_) => const AddNetworkSearchScreen()),
      );
    } else if (type == 'location_reminder' ||
        screen == 'networklocationpermissions') {
      nav.push(
        MaterialPageRoute(
          builder: (_) => const NetworkLocationPermissionsScreen(),
        ),
      );
    } else {
      log('[FCM] Unhandled notification payload type: $type, screen: $screen');
    }
  }
}
