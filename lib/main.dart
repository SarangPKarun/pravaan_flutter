import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/local/hive_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initialize();
  await SupabaseClientService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
