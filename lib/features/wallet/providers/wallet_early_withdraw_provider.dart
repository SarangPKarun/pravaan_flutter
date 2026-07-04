import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../../streak/models/streak_stats.dart';
import '../../streak/providers/streak_provider.dart';
import '../../streak/repositories/streak_repository.dart';
import '../repositories/wallet_repository.dart';

enum WalletEarlyWithdrawStatus { idle, submitting, success, error }

class WalletEarlyWithdrawState {
  const WalletEarlyWithdrawState({
    this.status = WalletEarlyWithdrawStatus.idle,
    this.errorMessage,
  });

  final WalletEarlyWithdrawStatus status;
  final String? errorMessage;

  WalletEarlyWithdrawState copyWith({
    WalletEarlyWithdrawStatus? status,
    String? errorMessage,
  }) =>
      WalletEarlyWithdrawState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class WalletEarlyWithdrawNotifier extends Notifier<WalletEarlyWithdrawState> {
  @override
  WalletEarlyWithdrawState build() => const WalletEarlyWithdrawState();

  Future<void> confirmEarlyWithdrawal(String habitId) async {
    state = state.copyWith(status: WalletEarlyWithdrawStatus.submitting);

    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        status: WalletEarlyWithdrawStatus.error,
        errorMessage: 'Not authenticated',
      );
      return;
    }

    final walletResult =
        await ref.read(walletRepositoryProvider).forceEarlyWithdrawal(habitId, userId);
    if (walletResult case Err(:final error)) {
      state = state.copyWith(
        status: WalletEarlyWithdrawStatus.error,
        errorMessage: error,
      );
      return;
    }

    final current = ref.read(streakProvider);
    final newStats = StreakStats(
      currentStreak: 0,
      longestStreak: current.longestStreak > current.currentStreak
          ? current.longestStreak
          : current.currentStreak,
      totalCleanDays: current.totalCleanDays,
      lastCheckinDate: current.lastCheckinDate,
    );
    // Instant local update so the dashboard/health screens reflect the reset
    // without waiting on the network write below.
    ref.read(streakProvider.notifier).updateStats(newStats);

    final streakResult =
        await ref.read(streakRepositoryProvider).updateStreak(userId, newStats);
    state = switch (streakResult) {
      Ok() => state.copyWith(status: WalletEarlyWithdrawStatus.success),
      Err(:final error) =>
        state.copyWith(status: WalletEarlyWithdrawStatus.error, errorMessage: error),
    };
  }
}

final walletEarlyWithdrawProvider =
    NotifierProvider<WalletEarlyWithdrawNotifier, WalletEarlyWithdrawState>(
  WalletEarlyWithdrawNotifier.new,
);
