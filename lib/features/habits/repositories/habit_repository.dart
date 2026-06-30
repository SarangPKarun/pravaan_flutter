import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/habit_model.dart';

class HabitRepository {
  const HabitRepository(this._client);

  final SupabaseClient _client;

  /// Inserts a new habit. The [habit.id] field is ignored — Supabase generates
  /// the UUID via gen_random_uuid(). Returns the persisted row.
  Future<Result<HabitModel, String>> createHabit(HabitModel habit) async {
    try {
      final payload = habit.toJson()..remove('id');
      final row =
          await _client.from('habits').insert(payload).select().single();
      return Ok(HabitModel.fromJson(row));
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<Result<List<HabitModel>, String>> getHabits(String userId) async {
    try {
      final rows = await _client
          .from('habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return Ok(rows.map(HabitModel.fromJson).toList());
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<Result<HabitModel, String>> updateHabit(HabitModel habit) async {
    try {
      final row = await _client
          .from('habits')
          .update(habit.toJson())
          .eq('id', habit.id)
          .select()
          .single();
      return Ok(HabitModel.fromJson(row));
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<Result<void, String>> deleteHabit(String id) async {
    try {
      await _client.from('habits').delete().eq('id', id);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(ref.watch(supabaseClientProvider)),
);
