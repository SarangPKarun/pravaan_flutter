import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/transaction_model.dart';

// ── Wallet data ───────────────────────────────────────────────────────────────

class WalletData {
  const WalletData({
    required this.balance,
    required this.dailySavings,
    required this.targetAmount,
    required this.quitDate,
    required this.transactions,
  });

  final double balance;
  final double dailySavings;
  final double targetAmount; // 1-year goal
  final DateTime? quitDate;
  final List<TransactionModel> transactions;

  double get progressFraction =>
      targetAmount > 0 ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get progressPercent => progressFraction * 100;
}

// ── Provider — computed balance (synchronous) ─────────────────────────────────

final walletDataProvider = Provider<WalletData>((ref) {
  final dashboard = ref.watch(dashboardProvider);
  return WalletData(
    balance: dashboard.totalSaved,
    dailySavings: dashboard.dailySavings,
    targetAmount: dashboard.dailySavings * 365,
    quitDate: dashboard.quitDate,
    transactions: const [], // populated by walletTransactionsProvider
  );
});

// ── Provider — transaction history (async, fetches from Supabase) ─────────────

final walletTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final rows = await client
        .from('wallet_transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(50);

    return (rows as List)
        .map((r) => TransactionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } catch (_) {
    // Table may not exist yet — return empty list rather than crashing
    return [];
  }
});

// ── Redeem notifier ───────────────────────────────────────────────────────────

class RedeemNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> redeem(String option, double amount) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await client.from('wallet_transactions').insert({
        'user_id': userId,
        'date': DateTime.now().toUtc().toIso8601String(),
        'amount': -amount,
        'type': TransactionType.redeemed.name,
        'description': option,
      });

      // Invalidate the transaction list so it refreshes
      ref.invalidate(walletTransactionsProvider);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final redeemProvider =
    NotifierProvider<RedeemNotifier, AsyncValue<void>>(RedeemNotifier.new);
