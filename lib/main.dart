import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/badges.dart';
import 'core/constants/app_constants.dart';
import 'core/local/hive_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'features/badges/providers/badge_provider.dart';
import 'features/notifications/services/local_notification_service.dart';
import 'features/notifications/services/push_notification_service.dart';
import 'features/streak/providers/streak_provider.dart';
import 'features/wallet/providers/wallet_list_provider.dart';
import 'firebase_options.dart';

void _logUncaughtError(Object error, StackTrace stack) {
  debugPrint('!!! UNCAUGHT ERROR !!! $error\n$stack');
}

Future<void> main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _logUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _logUncaughtError(error, stack);
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await HiveService.initialize();
    await SupabaseClientService.initialize();
    await PushNotificationService.requestPermission();
    await PushNotificationService.registerTokenForCurrentUser();
    PushNotificationService.listenForTokenRefresh();
    await LocalNotificationService.initialize();
    runApp(const ProviderScope(child: MyApp()));
  }, _logUncaughtError);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Watched (not just listened) so both the initial value on app launch
    // and every subsequent change trigger a (re)sync — `WidgetRef.listen`
    // in this Riverpod version has no `fireImmediately`, and the initial
    // state matters here (e.g. catching a milestone crossed while the app
    // was closed). Both service calls are idempotent, so re-running them
    // on incidental MyApp rebuilds is harmless.
    final isCheckedInToday = ref.watch(isCheckedInTodayProvider);
    LocalNotificationService.syncCheckinReminders(isCheckedInToday);

    final walletsAsync = ref.watch(userWalletsProvider);
    for (final wallet in walletsAsync.value ?? const []) {
      LocalNotificationService.notifyWalletMilestoneIfCrossed(wallet);
    }
    if (walletsAsync.value != null) {
      final totalSavings = ref.watch(totalSavingsProvider);
      ref.read(badgeAwardProvider.notifier).checkThresholds(savingsAmount: totalSavings);
    }

    // Pushes the celebration screen whenever a new badge becomes the one
    // awaiting celebration — fires for the first unlock and, after the
    // screen calls `dismiss()`, again for each subsequently queued one.
    ref.listen<BadgeModel?>(badgeAwardProvider, (previous, next) {
      if (next != null && next != previous) {
        router.push('/badge-celebration', extra: next);
      }
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
