import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/goal_wallet_model.dart';
import '../repositories/wallet_repository.dart';

final userWalletsProvider = FutureProvider<List<GoalWalletModel>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];

  final result = await ref.watch(walletRepositoryProvider).getWallets(userId);
  final wallets = switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
  wallets.sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
  return wallets;
});
