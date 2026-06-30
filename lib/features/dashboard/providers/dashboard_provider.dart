import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../../streak/providers/streak_provider.dart';

// ── Data model ───────────────────────────────────────────────────────────────

class DashboardData {
  const DashboardData({
    required this.displayName,
    required this.habitType,
    required this.daysClean,
    required this.longestStreak,
    required this.totalCleanDays,
    required this.dailySavings,
    required this.quitDate,
  });

  final String displayName;
  final String habitType;

  /// Current clean streak from streak_provider (Hive-backed, instant).
  final int daysClean;

  /// All-time longest streak.
  final int longestStreak;

  /// Cumulative clean days (not reset on slip).
  final int totalCleanDays;

  final double dailySavings;
  final DateTime? quitDate;

  double get totalSaved => daysClean * dailySavings;

  /// Milestone-based motivational messages.
  String get motivationalMessage {
    if (daysClean == 0)   return "Today is Day 1. Every journey starts with a single step. You've got this! 💪";
    if (daysClean == 1)   return "You survived Day 1! Your body is already thanking you. Keep going. 🌱";
    if (daysClean < 3)    return "A few days in and your willpower is already stronger than your craving. Stay strong! 🔥";
    if (daysClean < 7)    return "Almost a week! Your lungs are starting to clear. Keep it up! 🌬️";
    if (daysClean == 7)   return "One full week clean! Your sense of taste and smell are improving. Amazing! 🎉";
    if (daysClean < 14)   return "Double digits approaching! You've broken the back of the habit cycle. 💎";
    if (daysClean == 14)  return "Two weeks! Nicotine cravings have dropped by over 50%. You're winning! 🏆";
    if (daysClean < 30)   return "You're on fire! Most cravings are now gone. Your future self is proud. ⭐";
    if (daysClean < 60)   return "One month clean! Your circulation has improved and energy is up. Legend! 🦁";
    if (daysClean < 90)   return "Two months of freedom! Your lungs have regained significant capacity. 🌟";
    if (daysClean < 180)  return "Three months clean! You've saved enough for a real treat. Reward yourself! 🎁";
    if (daysClean < 365)  return "Half a year free! Your risk of heart disease has already dropped. Incredible! 💚";
    return "One whole year! You've completely transformed your health and your finances. LEGEND. 👑";
  }

  String get streakEmoji {
    if (daysClean < 3)   return '🌱';
    if (daysClean < 7)   return '🔥';
    if (daysClean < 30)  return '⚡';
    if (daysClean < 90)  return '💎';
    if (daysClean < 365) return '🏆';
    return '👑';
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final dashboardProvider = Provider<DashboardData>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  final meta = user?.userMetadata ?? {};

  // ── Parse user metadata ────────────────────────────────────────────────
  final displayName =
      (meta['display_name'] as String?)?.trim().isNotEmpty == true
          ? meta['display_name'] as String
          : (user?.email?.split('@').first ?? 'Friend');

  final habitType = (meta['habit_type'] as String?) ?? 'habit';

  final dailyQty     = (meta['daily_qty']  as num?)?.toInt()    ?? 0;
  final unitCost     = (meta['unit_cost']  as num?)?.toDouble() ?? 0.0;
  final dailySavings = dailyQty * unitCost;

  final quitDateRaw = meta['quit_date'] as String?;
  final quitDate    = quitDateRaw != null ? DateTime.tryParse(quitDateRaw) : null;

  // ── Streak stats from Hive-backed provider (instant, no async) ─────────
  final streak = ref.watch(streakProvider);

  return DashboardData(
    displayName: displayName,
    habitType: habitType,
    daysClean: streak.currentStreak,
    longestStreak: streak.longestStreak,
    totalCleanDays: streak.totalCleanDays,
    dailySavings: dailySavings,
    quitDate: quitDate,
  );
});
