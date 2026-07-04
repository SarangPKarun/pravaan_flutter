import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../exceptions/wallet_exceptions.dart';
import '../repositories/wallet_repository.dart';

enum WalletWithdrawStatus { idle, submitting, success, error }

class WalletWithdrawState {
  const WalletWithdrawState({
    this.status = WalletWithdrawStatus.idle,
    this.errorMessage,
  });

  final WalletWithdrawStatus status;
  final String? errorMessage;

  WalletWithdrawState copyWith({
    WalletWithdrawStatus? status,
    String? errorMessage,
  }) =>
      WalletWithdrawState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class WalletWithdrawNotifier extends Notifier<WalletWithdrawState> {
  @override
  WalletWithdrawState build() => const WalletWithdrawState();

  Future<void> withdraw(String habitId, {String? upiId}) async {
    state = state.copyWith(status: WalletWithdrawStatus.submitting);

    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        status: WalletWithdrawStatus.error,
        errorMessage: 'Not authenticated',
      );
      return;
    }

    try {
      final result = await ref
          .read(walletRepositoryProvider)
          .requestWithdrawal(habitId, userId, upiId: upiId);
      state = switch (result) {
        Ok() => state.copyWith(status: WalletWithdrawStatus.success),
        Err(:final error) =>
          state.copyWith(status: WalletWithdrawStatus.error, errorMessage: error),
      };
    } on WalletLockedException catch (e) {
      state = state.copyWith(
        status: WalletWithdrawStatus.error,
        errorMessage: e.message,
      );
    }
  }
}

final walletWithdrawProvider =
    NotifierProvider<WalletWithdrawNotifier, WalletWithdrawState>(
  WalletWithdrawNotifier.new,
);
