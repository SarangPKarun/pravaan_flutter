import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../notifications/services/push_notification_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      next.whenData((s) => state = AsyncData(s.session?.user));
    });
    return ref.read(supabaseClientProvider).auth.currentUser;
  }

  /// Send OTP to [phone] in E.164 format (e.g. +919876543210).
  /// State stays at its current value after success — user is not signed in
  /// until [verifyOtp] completes.
  Future<void> sendOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(() async {
      await ref.read(supabaseClientProvider).auth.signInWithOtp(phone: phone);
      return null; // not authenticated yet
    });
  }

  /// Verify the 6-digit [token] received via SMS for [phone].
  /// On success the auth state stream fires and [build] updates state.
  Future<void> verifyOtp(String phone, String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(() async {
      final res = await ref.read(supabaseClientProvider).auth.verifyOTP(
            phone: phone,
            token: token,
            type: OtpType.sms,
          );
      // Register this device's FCM token now that a session exists —
      // main()'s registration runs before login, so a brand-new sign-in
      // needs its own call.
      await PushNotificationService.registerTokenForCurrentUser();
      return res.user;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(() async {
      await ref.read(supabaseClientProvider).auth.signOut();
      return null;
    });
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc('delete_user');
      await client.auth.signOut();
      return null;
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
