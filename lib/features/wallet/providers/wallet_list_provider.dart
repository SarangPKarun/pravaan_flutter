import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../models/goal_wallet_model.dart';
import '../repositories/wallet_repository.dart';

/// Live list of the user's goal wallets — updates in real time via Supabase
/// Realtime (see `WalletRepository.watchWallets`) whenever a row changes,
/// e.g. when the daily-wallet-credit Edge Function credits a balance.
final userWalletsProvider = StreamProvider<List<GoalWalletModel>>((ref) {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return Stream.value(<GoalWalletModel>[]);

  return ref.watch(walletRepositoryProvider).watchWallets(userId);
});
