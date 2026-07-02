import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/checkin_model.dart';

class CheckinRepository {
  const CheckinRepository(this._client);

  final SupabaseClient _client;

  /// Full check-in history for [userId], chronological (oldest first) — the
  /// order mood/streak insights need to reconstruct streak position per day.
  Future<Result<List<CheckinModel>, String>> getHistory(String userId) async {
    try {
      final rows = await _client
          .from('checkins')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);
      return Ok(
        rows.map((r) => CheckinModel.fromJson(Map<String, dynamic>.from(r))).toList(),
      );
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(ref.watch(supabaseClientProvider)),
);
