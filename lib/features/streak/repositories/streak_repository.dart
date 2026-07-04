import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../../checkin/models/checkin_model.dart';
import '../models/streak_stats.dart';

class StreakRepository {
  const StreakRepository(this._client);

  final SupabaseClient _client;

  /// Fetches the user's streak stats from `public.user_stats`.
  /// Returns zero-defaults when the row doesn't exist yet (new user).
  Future<Result<StreakStats, String>> getStreak(String userId) async {
    try {
      final row = await _client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return Ok(row != null
          ? StreakStats.fromJson(Map<String, dynamic>.from(row))
          : const StreakStats());
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Upserts streak stats into `public.user_stats`.
  Future<Result<void, String>> updateStreak(
      String userId, StreakStats stats) async {
    try {
      await _client.from('user_stats').upsert({
        'user_id': userId,
        ...stats.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Returns the most recent check-in row for today (UTC), or null if none.
  Future<Result<CheckinModel?, String>> getTodayCheckin(String userId) async {
    try {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));

      final row = await _client
          .from('checkins')
          .select()
          .eq('user_id', userId)
          .gte('date', todayStart.toIso8601String())
          .lt('date', tomorrowStart.toIso8601String())
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      return Ok(row != null
          ? CheckinModel.fromJson(Map<String, dynamic>.from(row))
          : null);
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final streakRepositoryProvider = Provider<StreakRepository>(
  (ref) => StreakRepository(ref.watch(supabaseClientProvider)),
);
