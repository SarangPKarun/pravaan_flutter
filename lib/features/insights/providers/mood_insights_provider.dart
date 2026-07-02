import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../../checkin/models/checkin_model.dart';
import '../../checkin/repositories/checkin_repository.dart';
import '../../../core/result.dart';

const _minBucketSize = 3;
const _maxChartPoints = 30;

class MoodPoint {
  const MoodPoint({required this.date, required this.mood, required this.isClean});
  final DateTime date;
  final int mood;
  final bool isClean;
}

class MoodInsights {
  const MoodInsights({required this.chartPoints, required this.highlightText});
  final List<MoodPoint> chartPoints;

  /// Null when there isn't enough check-in history yet to support the claim.
  final String? highlightText;

  static const empty = MoodInsights(chartPoints: [], highlightText: null);
}

final checkinHistoryProvider = FutureProvider<List<CheckinModel>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];

  final result = await ref.watch(checkinRepositoryProvider).getHistory(userId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
});

final moodInsightsProvider = Provider<MoodInsights>((ref) {
  final history = ref.watch(checkinHistoryProvider).value;
  if (history == null || history.isEmpty) return MoodInsights.empty;

  // ── Reconstruct each clean check-in's position within its streak ────────
  // Mirrors the day-contiguity logic in CheckinNotifier._computeNewStats:
  // consecutive calendar days, not just consecutive rows; a slip resets it.
  final earlyMoods = <int>[]; // day 1-2 of a clean streak
  final lateMoods = <int>[]; // day 3+ of a clean streak
  var streakDay = 0;
  DateTime? lastCleanDay;

  for (final checkin in history) {
    final day = DateTime(checkin.date.year, checkin.date.month, checkin.date.day);

    if (!checkin.isClean) {
      streakDay = 0;
      lastCleanDay = null;
      continue;
    }

    if (lastCleanDay != null && day.isAtSameMomentAs(lastCleanDay)) {
      // Same calendar day as the last clean entry — don't double count.
    } else if (lastCleanDay != null &&
        day.difference(lastCleanDay).inDays == 1) {
      streakDay += 1;
    } else {
      streakDay = 1;
    }
    lastCleanDay = day;

    (streakDay >= 3 ? lateMoods : earlyMoods).add(checkin.mood);
  }

  String? highlight;
  if (earlyMoods.length >= _minBucketSize && lateMoods.length >= _minBucketSize) {
    final earlyAvg = earlyMoods.reduce((a, b) => a + b) / earlyMoods.length;
    final lateAvg = lateMoods.reduce((a, b) => a + b) / lateMoods.length;
    if (lateAvg > earlyAvg) {
      highlight = 'Your mood is highest on day 3+ of clean streaks.';
    }
  }

  final recent = history.length > _maxChartPoints
      ? history.sublist(history.length - _maxChartPoints)
      : history;

  return MoodInsights(
    chartPoints: [
      for (final checkin in recent)
        MoodPoint(date: checkin.date, mood: checkin.mood, isClean: checkin.isClean),
    ],
    highlightText: highlight,
  );
});
