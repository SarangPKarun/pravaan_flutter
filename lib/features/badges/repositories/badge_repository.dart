import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';

class BadgeRepository {
  const BadgeRepository(this._client);

  final SupabaseClient _client;

  /// Fetches the set of badge ids the user has already earned from
  /// `public.user_badges`.
  Future<Result<Set<String>, String>> getEarnedBadgeIds(String userId) async {
    try {
      final rows = await _client
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId);
      return Ok(rows.map((row) => row['badge_id'] as String).toSet());
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Records a newly earned badge. A duplicate insert (e.g. a race with
  /// another device) is treated as success thanks to the unique constraint
  /// on `(user_id, badge_id)`.
  Future<Result<void, String>> awardBadge(String userId, String badgeId) async {
    try {
      await _client.from('user_badges').insert({
        'user_id': userId,
        'badge_id': badgeId,
      });
      return const Ok(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return const Ok(null);
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final badgeRepositoryProvider = Provider<BadgeRepository>(
  (ref) => BadgeRepository(ref.watch(supabaseClientProvider)),
);
