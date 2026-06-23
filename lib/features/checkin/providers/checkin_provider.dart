import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';

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

  /// Inserts a check-in row into `public.checkins`.
  /// [mood] is 1–5.
  Future<void> submitCheckin({
    required bool isClean,
    required int mood,
    String? note,
  }) async {
    state = state.copyWith(status: CheckinStatus.submitting);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await client.from('checkins').insert({
        'user_id': userId,
        'date': DateTime.now().toUtc().toIso8601String(),
        'is_clean': isClean,
        'mood': mood,
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      });

      state = state.copyWith(status: CheckinStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: CheckinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const CheckinState();
}

final checkinProvider =
    NotifierProvider<CheckinNotifier, CheckinState>(CheckinNotifier.new);
