import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/goal_wallet_model.dart';
import '../repositories/wallet_repository.dart';

enum WalletCreateStatus { idle, submitting, success, error }

class WalletCreateState {
  const WalletCreateState({
    this.status = WalletCreateStatus.idle,
    this.errorMessage,
  });

  final WalletCreateStatus status;
  final String? errorMessage;

  WalletCreateState copyWith({
    WalletCreateStatus? status,
    String? errorMessage,
  }) =>
      WalletCreateState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class WalletCreateNotifier extends Notifier<WalletCreateState> {
  @override
  WalletCreateState build() => const WalletCreateState();

  Future<void> createWallet({
    required String habitId,
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    state = state.copyWith(status: WalletCreateStatus.submitting);

    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        status: WalletCreateStatus.error,
        errorMessage: 'Not authenticated',
      );
      return;
    }

    final wallet = GoalWalletModel(
      id: '',
      habitId: habitId,
      goalName: goalName,
      targetAmount: targetAmount,
      currentBalance: 0,
      targetDate: targetDate,
      isLocked: true,
    );

    final result =
        await ref.read(walletRepositoryProvider).createWallet(wallet, userId);
    state = switch (result) {
      Ok() => state.copyWith(status: WalletCreateStatus.success),
      Err(:final error) =>
        state.copyWith(status: WalletCreateStatus.error, errorMessage: error),
    };
  }
}

final walletCreateProvider =
    NotifierProvider<WalletCreateNotifier, WalletCreateState>(
  WalletCreateNotifier.new,
);
