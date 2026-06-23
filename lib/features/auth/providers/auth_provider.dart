import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

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

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithPassword(email: email, password: password);
      return res.user;
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await ref
          .read(supabaseClientProvider)
          .auth
          .signUp(email: email, password: password);
      return res.session?.user; // null if email confirmation required
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    // signInWithOAuth launches Chrome Custom Tabs and returns immediately.
    // Android intercepts the redirect URI via the intent-filter in
    // AndroidManifest.xml, which fires onAuthStateChange → build() listener.
    await AsyncValue.guard<void>(() => ref
        .read(supabaseClientProvider)
        .auth
        .signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.pravaan.pravaan_flutter://login-callback',
        ));
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<User?>(() async {
      await ref.read(supabaseClientProvider).auth.signOut();
      return null;
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
