import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/local/hive_service.dart';
import '../../../core/supabase_client.dart';
import '../../badges/providers/badge_provider.dart';
import '../../streak/models/streak_stats.dart';
import '../../streak/providers/streak_provider.dart';
import '../../streak/repositories/streak_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum CheckinStatus { idle, submitting, success, error }

class CheckinState {
  const CheckinState({
    this.status = CheckinStatus.idle,
    this.errorMessage,
  });

  final CheckinStatus status;
  final String? errorMessage;

  CheckinState copyWith({CheckinStatus? status, String? errorMessage}) =>
      CheckinState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class CheckinNotifier extends Notifier<CheckinState> {
  @override
  CheckinState build() => const CheckinState();

  /// Inserts a check-in row and updates streak stats.
  /// Writes to Hive first (always succeeds), then syncs to Supabase.
  /// On network failure the payloads are queued and retried on the next call.
  Future<void> submitCheckin({
    required bool isClean,
    required int mood,
    int? cravingIntensity,
    String? cravingTrigger,
    String? cravingTime,
    String? note,
  }) async {
    state = state.copyWith(status: CheckinStatus.submitting);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // 1. Compute new streak stats based on current local state.
      final current = ref.read(streakProvider);
      final newStats = _computeNewStats(current, isClean);

      // 2. Persist to Hive immediately — UI updates without waiting for network.
      ref.read(streakProvider.notifier).updateStats(newStats);

      // 2b. Check for newly-earned day-count/streak badges against the fresh stats.
      await ref.read(badgeAwardProvider.notifier).checkThresholds(
            dayCount: newStats.totalCleanDays,
            streakLength: newStats.currentStreak,
          );

      // 3. Flush previously queued items before adding new ones.
      await _flushPendingSync(client);

      // 4. Try Supabase; on network error, add to queue instead.
      final checkinPayload = {
        'user_id': userId,
        'date': DateTime.now().toUtc().toIso8601String(),
        'is_clean': isClean,
        'mood': mood,
        'craving_intensity': isClean ? null : cravingIntensity,
        'craving_trigger': isClean ? null : cravingTrigger,
        'craving_time': isClean ? null : cravingTime,
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      };
      // Raw stats map kept for the offline queue (avoids repo dependency at flush time).
      final statsPayload = {
        'user_id': userId,
        ...newStats.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        await client.from('checkins').insert(checkinPayload);
        await ref
            .read(streakRepositoryProvider)
            .updateStreak(userId, newStats);
      } catch (_) {
        // Offline: queue for later sync.
        await HiveService.pendingBox
            .add({'checkin': checkinPayload, 'stats': statsPayload});
      }

      state = state.copyWith(status: CheckinStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: CheckinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const CheckinState();

  // ── Streak computation ──────────────────────────────────────────────────

  StreakStats _computeNewStats(StreakStats current, bool isClean) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final last = current.lastCheckinDate;
    final lastDay =
        last != null ? DateTime(last.year, last.month, last.day) : null;

    final alreadyCheckedInToday =
        lastDay != null && lastDay.isAtSameMomentAs(today);

    if (!isClean) {
      return StreakStats(
        currentStreak: 0,
        longestStreak: max(current.longestStreak, current.currentStreak),
        totalCleanDays: current.totalCleanDays,
        lastCheckinDate: today,
      );
    }

    // isClean == true
    if (alreadyCheckedInToday) {
      // Already counted today — don't double-increment.
      return current;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    final isConsecutive =
        lastDay != null && lastDay.isAtSameMomentAs(yesterday);

    final newStreak = isConsecutive ? current.currentStreak + 1 : 1;

    return StreakStats(
      currentStreak: newStreak,
      longestStreak: max(current.longestStreak, newStreak),
      totalCleanDays: current.totalCleanDays + 1,
      lastCheckinDate: today,
    );
  }

  // ── Offline sync flush ──────────────────────────────────────────────────

  Future<void> _flushPendingSync(SupabaseClient client) async {
    final box = HiveService.pendingBox;
    if (box.isEmpty) return;

    final keys = box.keys.toList();
    for (final key in keys) {
      final entry = box.get(key) as Map?;
      if (entry == null) continue;
      try {
        final checkin = Map<String, dynamic>.from(entry['checkin'] as Map);
        final stats = Map<String, dynamic>.from(entry['stats'] as Map);
        await client.from('checkins').insert(checkin);
        await client.from('user_stats').upsert(stats);
        await box.delete(key);
      } catch (_) {
        // Still offline — stop trying; remainder stays queued.
        break;
      }
    }
  }
}

final checkinProvider =
    NotifierProvider<CheckinNotifier, CheckinState>(CheckinNotifier.new);
