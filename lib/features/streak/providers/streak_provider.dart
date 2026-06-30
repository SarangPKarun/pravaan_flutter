import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/streak_stats.dart';
import '../repositories/streak_repository.dart';

class StreakNotifier extends Notifier<StreakStats> {
  @override
  StreakStats build() {
    // Return local Hive cache immediately — no async wait.
    final local = StreakStats.fromHive();
    // Background-refresh from Supabase without blocking the build.
    Future.microtask(_refreshFromSupabase);
    return local;
  }

  /// Write to Hive + update state. Called by checkin_provider after computing
  /// new stats so the dashboard reflects the change instantly.
  void updateStats(StreakStats stats) {
    stats.saveToHive();
    state = stats;
  }

  Future<void> _refreshFromSupabase() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final result =
        await ref.read(streakRepositoryProvider).getStreak(userId);
    if (result case Ok(:final value)) {
      value.saveToHive();
      state = value;
    }
    // On Err (offline / network): silently keep local Hive cache.
  }
}

final streakProvider =
    NotifierProvider<StreakNotifier, StreakStats>(StreakNotifier.new);

// ── Named field providers ─────────────────────────────────────────────────────
// Widgets watching these only rebuild when that specific value changes.

final currentStreakProvider =
    Provider<int>((ref) => ref.watch(streakProvider).currentStreak);

final longestStreakProvider =
    Provider<int>((ref) => ref.watch(streakProvider).longestStreak);

final lastCheckinDateProvider =
    Provider<DateTime?>((ref) => ref.watch(streakProvider).lastCheckinDate);

final isCheckedInTodayProvider =
    Provider<bool>((ref) => ref.watch(streakProvider).isCheckedInToday);
