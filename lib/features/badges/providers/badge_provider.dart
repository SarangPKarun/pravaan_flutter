import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/badges.dart';
import '../../../core/local/hive_service.dart';
import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../../notifications/services/local_notification_service.dart';
import '../repositories/badge_repository.dart';

/// Tracks which badge (if any) should currently be celebrated, and awards
/// newly-crossed badges as check-in/wallet stats come in.
class BadgeAwardNotifier extends Notifier<BadgeModel?> {
  final Set<String> _earnedIds = {};
  final Queue<BadgeModel> _pending = Queue();
  final Completer<void> _ready = Completer<void>();

  @override
  BadgeModel? build() {
    Future.microtask(_loadEarnedIds);
    return null;
  }

  Future<void> _loadEarnedIds() async {
    try {
      final box = HiveService.badgesBox;
      _earnedIds.addAll(box.keys.cast<String>());

      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId != null) {
        final result = await ref.read(badgeRepositoryProvider).getEarnedBadgeIds(userId);
        if (result case Ok(:final value)) {
          for (final id in value) {
            _earnedIds.add(id);
            if (!box.containsKey(id)) {
              await box.put(id, DateTime.now().toUtc().toIso8601String());
            }
          }
        }
      }
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Compares the given stats against the badge catalog and awards any
  /// newly-crossed, not-yet-earned badge. Pass only the values relevant to
  /// the event that just happened (e.g. day/streak counts after a check-in,
  /// or total savings after a wallet credit).
  Future<void> checkThresholds({
    int? dayCount,
    int? streakLength,
    num? savingsAmount,
  }) async {
    try {
      await _ready.future;

      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId == null) return;

      for (final badge in badges) {
        if (_earnedIds.contains(badge.id)) continue;

        final progress = switch (badge.triggerCondition) {
          BadgeTriggerCondition.dayCount => dayCount,
          BadgeTriggerCondition.streakLength => streakLength,
          BadgeTriggerCondition.savingsAmount => savingsAmount,
          BadgeTriggerCondition.custom => null,
        };
        if (progress == null || progress < badge.thresholdValue) continue;

        _earnedIds.add(badge.id);
        await HiveService.badgesBox.put(badge.id, DateTime.now().toUtc().toIso8601String());
        unawaited(ref.read(badgeRepositoryProvider).awardBadge(userId, badge.id));
        unawaited(LocalNotificationService.notifyBadgeEarned(badge));

        if (state == null) {
          state = badge;
        } else {
          _pending.add(badge);
        }
      }
    } catch (_) {
      // Badge-check failures must never surface as a check-in/wallet error.
    }
  }

  /// Dismisses the badge currently being celebrated and advances to the
  /// next queued one, if any.
  void dismiss() {
    state = _pending.isNotEmpty ? _pending.removeFirst() : null;
  }
}

final badgeAwardProvider =
    NotifierProvider<BadgeAwardNotifier, BadgeModel?>(BadgeAwardNotifier.new);
