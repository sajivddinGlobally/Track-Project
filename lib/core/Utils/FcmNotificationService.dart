import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/DrawerScreen/NetworkLocationpermissions.dart';
import 'package:track_loved/core/AuthService/AuthService.dart';
import 'package:track_loved/core/Utils/key.dart';

class FcmNotificationService {
  /// Syncs FCM token to backend using PATCH /api/v1/auth/fcm-token
  static Future<void> syncFcmToken(
    String fcmToken, {
    required Authservice authService,
    bool force = false,
  }) async {
    try {
      if (fcmToken.trim().isEmpty) return;

      final box = Hive.isBoxOpen('userdata')
          ? Hive.box('userdata')
          : await Hive.openBox('userdata');

      final lastSyncedToken = box.get('synced_fcm_token')?.toString();
      if (!force && lastSyncedToken == fcmToken) {
        debugPrint('[FCM] Token already synced with backend');
        return;
      }

      final res = await authService.updateFcmTokenData(fcmToken);
      debugPrint('[FCM] Token synced successfully: $res');
      await box.put('synced_fcm_token', fcmToken);
    } catch (e) {
      debugPrint('[FCM] Failed to sync FCM token: $e');
    }
  }

  /// Handles incoming notification data payload.
  /// When screen == 'NetworkLocationPermissions', redirects to NetworkLocationPermissionsScreen.
  static void handleNotificationPayload(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('[FCM] Handling notification data: $data');

    final screen = data['screen']?.toString();
    if (screen == 'NetworkLocationPermissions') {
      navigateToLocationPermissions();
    }
  }

  /// Navigates directly to NetworkLocationPermissionsScreen using the global navigatorKey
  static void navigateToLocationPermissions() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('[FCM] NavigatorState not ready yet');
      return;
    }
    nav.push(
      MaterialPageRoute(
        builder: (_) => const NetworkLocationPermissionsScreen(),
      ),
    );
  }
}

