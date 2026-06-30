import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class HabitNotifier extends AsyncNotifier<List<HabitModel>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  Future<List<HabitModel>> build() async {
    ref.watch(authStateProvider); // re-runs on sign-in / sign-out
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return [];

    final result = await _repo.getHabits(userId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final error) => throw Exception(error),
    };
  }

  Future<Result<HabitModel, String>> addHabit(HabitModel habit) async {
    final result = await _repo.createHabit(habit);
    if (result case Ok(:final value)) {
      state = AsyncData([value, ...state.requireValue]);
    }
    return result;
  }

  Future<Result<HabitModel, String>> editHabit(HabitModel habit) async {
    final result = await _repo.updateHabit(habit);
    if (result case Ok(:final value)) {
      state = AsyncData([
        for (final h in state.requireValue)
          if (h.id == value.id) value else h,
      ]);
    }
    return result;
  }

  Future<Result<void, String>> removeHabit(String id) async {
    final result = await _repo.deleteHabit(id);
    if (result case Ok()) {
      state = AsyncData(
        state.requireValue.where((h) => h.id != id).toList(),
      );
    }
    return result;
  }
}

final habitNotifierProvider =
    AsyncNotifierProvider<HabitNotifier, List<HabitModel>>(HabitNotifier.new);

// ── Selected habit ────────────────────────────────────────────────────────────

class _SelectedHabitIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

/// Writable cursor — call `.notifier.select(id)` to select, `.select(null)` to clear.
final selectedHabitIdProvider =
    NotifierProvider<_SelectedHabitIdNotifier, String?>(
  _SelectedHabitIdNotifier.new,
);

/// Resolves the full HabitModel from the list for the selected id.
final selectedHabitProvider = Provider<HabitModel?>((ref) {
  final id = ref.watch(selectedHabitIdProvider);
  if (id == null) return null;
  final habits = ref.watch(habitNotifierProvider).value ?? [];
  return habits.where((h) => h.id == id).firstOrNull;
});

// ── Daily spend ───────────────────────────────────────────────────────────────

/// Sum of dailySpend (dailyUnits × costPerUnit) across all active habits.
final dailySpendProvider = Provider<double>((ref) {
  final habits = ref.watch(habitNotifierProvider).value ?? [];
  return habits
      .where((h) => h.isActive)
      .fold(0.0, (sum, h) => sum + h.dailySpend);
});
