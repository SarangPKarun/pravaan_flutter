import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/health/screens/health_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/sos/screens/sos_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../supabase_client.dart';

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  final client = ref.read(supabaseClientProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = client.auth.currentSession != null;
      final location = state.matchedLocation;

      if (!isLoggedIn) {
        return location == '/login' ? null : '/login';
      }

      final isOnboarded =
          client.auth.currentUser?.userMetadata?['is_onboarded'] == true;

      if (!isOnboarded) {
        return location == '/onboarding' ? null : '/onboarding';
      }

      if (location == '/login') return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/checkin', builder: (_, _) => const CheckinScreen()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
      GoRoute(path: '/health', builder: (_, _) => const HealthScreen()),
      GoRoute(path: '/sos', builder: (_, _) => const SosScreen()),
      GoRoute(path: '/marketplace', builder: (_, _) => const MarketplaceScreen()),
      GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
    ],
  );
});
