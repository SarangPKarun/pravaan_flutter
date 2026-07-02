import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/local/hive_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'features/notifications/services/local_notification_service.dart';
import 'features/notifications/services/push_notification_service.dart';
import 'features/streak/providers/streak_provider.dart';
import 'features/wallet/providers/wallet_list_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveService.initialize();
  await SupabaseClientService.initialize();
  await PushNotificationService.requestPermission();
  await PushNotificationService.registerTokenForCurrentUser();
  PushNotificationService.listenForTokenRefresh();
  await LocalNotificationService.initialize();
  runApp(const ProviderScope(child: MyApp()));
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

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
