import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

// ── Data model ──────────────────────────────────────────────────────────────

class OnboardingData {
  const OnboardingData({
    this.habitType,
    this.dailyQty = 5,
    this.unitCost = 15.0,
    this.quitDate,
  });

  final String? habitType;
  final int dailyQty;
  final double unitCost;
  final DateTime? quitDate;

  OnboardingData copyWith({
    String? habitType,
    int? dailyQty,
    double? unitCost,
    DateTime? quitDate,
  }) {
    return OnboardingData(
      habitType: habitType ?? this.habitType,
      dailyQty: dailyQty ?? this.dailyQty,
      unitCost: unitCost ?? this.unitCost,
      quitDate: quitDate ?? this.quitDate,
    );
  }

  // ── Computed savings helpers ────────────────────────────────────────────
  double get dailySpend => dailyQty * unitCost;
  double get weeklySavings => dailySpend * 7;
  double get monthlySavings => dailySpend * 30;
  double get sixMonthSavings => dailySpend * 180;
  double get yearlySavings => dailySpend * 365;

  /// Savings from quitDate up to [to]. Returns 0 if quitDate is null.
  double savingsBy(DateTime to) {
    if (quitDate == null) return 0;
    final days = to.difference(quitDate!).inDays;
    return days > 0 ? days * dailySpend : 0;
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  void setHabitType(String type) => state = state.copyWith(habitType: type);

  void setDailyQty(int qty) =>
      state = state.copyWith(dailyQty: qty.clamp(1, 100));

  void setUnitCost(double cost) =>
      state = state.copyWith(unitCost: cost.clamp(0.0, 99999.0));

  void setQuitDate(DateTime date) => state = state.copyWith(quitDate: date);

  /// Persists all onboarding data to Supabase user metadata and marks
  /// the user as onboarded. After this call succeeds, the caller should
  /// navigate to /home.
  Future<void> complete() async {
    final d = state;
    await ref.read(supabaseClientProvider).auth.updateUser(
          UserAttributes(data: {
            'is_onboarded': true,
            'habit_type': d.habitType,
            'daily_qty': d.dailyQty,
            'unit_cost': d.unitCost,
            'quit_date': d.quitDate?.toIso8601String(),
          }),
        );
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(
  OnboardingNotifier.new,
);
