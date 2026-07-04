import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/goal_wallet_model.dart';
import '../models/wallet_credit_model.dart';
import '../repositories/wallet_repository.dart';

final goalWalletProvider =
    FutureProvider.family<GoalWalletModel?, String>((ref, habitId) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return null;

  final result = await ref.watch(walletRepositoryProvider).getWallet(habitId, userId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
});

final walletCreditHistoryProvider =
    FutureProvider.family<List<WalletCreditModel>, String>((ref, habitId) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];

  final result =
      await ref.watch(walletRepositoryProvider).getCreditHistory(habitId, userId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
});
