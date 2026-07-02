import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/supabase_client.dart';

abstract final class PushNotificationService {
  /// Prompts for notification permission (alert/badge/sound). Safe to call
  /// on every app startup — the OS only shows the prompt once and this
  /// simply returns the existing grant/denial on subsequent calls.
  static Future<NotificationSettings> requestPermission() {
    return FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Fetches the current FCM token and upserts it against the signed-in
  /// user, so the morning-notification Edge Function has somewhere to send
  /// pushes. No-op if nobody is signed in yet. Best-effort — a failure here
  /// should never block app startup or login.
  static Future<void> registerTokenForCurrentUser() async {
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await SupabaseClientService.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
        onConflict: 'token',
      );
    } catch (e) {
      debugPrint('PushNotificationService: failed to register token — $e');
    }
  }

  /// FCM tokens can rotate at any time during a long-running session, not
  /// just at launch/login — keep `device_tokens` in sync when that happens.
  static void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => registerTokenForCurrentUser(),
      onError: (e) =>
          debugPrint('PushNotificationService: token refresh listener error — $e'),
    );
  }
}
