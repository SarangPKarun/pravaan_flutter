import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../../wallet/models/wallet_credit_model.dart';
import '../../wallet/repositories/wallet_repository.dart';

final allCreditHistoryProvider = FutureProvider<List<WalletCreditModel>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];

  final result = await ref.watch(walletRepositoryProvider).getAllCreditHistory(userId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
});

class CumulativeSavingsPoint {
  const CumulativeSavingsPoint({required this.date, required this.cumulativeAmount});
  final DateTime date;
  final double cumulativeAmount;
}

/// Running total of savings over time, one point per calendar day that had
/// at least one credit (across all of the user's wallets combined).
final cumulativeSavingsProvider = Provider<List<CumulativeSavingsPoint>>((ref) {
  final credits = ref.watch(allCreditHistoryProvider).value ?? const [];
  if (credits.isEmpty) return [];

  final byDate = <DateTime, double>{};
  for (final credit in credits) {
    final day = DateTime(credit.creditDate.year, credit.creditDate.month, credit.creditDate.day);
    byDate[day] = (byDate[day] ?? 0) + credit.amount;
  }

  final sortedDays = byDate.keys.toList()..sort();
  var running = 0.0;
  return [
    for (final day in sortedDays)
      CumulativeSavingsPoint(date: day, cumulativeAmount: running += byDate[day]!),
  ];
});
