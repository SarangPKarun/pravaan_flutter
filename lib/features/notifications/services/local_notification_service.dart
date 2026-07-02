import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/local/hive_service.dart';
import '../../wallet/models/goal_wallet_model.dart';

abstract final class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _checkinReminderId = 100;
  static const _streakAtRiskId = 101;
  static const _milestoneTiers = [25, 50, 75, 100];

  static const _reminderChannel = AndroidNotificationDetails(
    'checkin_reminders',
    'Check-in reminders',
    channelDescription: 'Evening reminders to log your daily check-in',
  );

  static const _milestoneChannel = AndroidNotificationDetails(
    'wallet_milestones',
    'Savings milestones',
    channelDescription: 'Celebrates progress toward your savings goals',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Sets up timezone data (for `zonedSchedule`) and initializes the plugin.
  /// Call once from `main()`.
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      // A timezone lookup failure shouldn't block app startup — scheduled
      // notifications fall back to whatever default location `timezone`
      // picked, which is still better than crashing.
      debugPrint('LocalNotificationService: timezone lookup failed — $e');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission already requested via PushNotificationService — iOS
        // shares one system permission across local and remote notifications.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Cancels both evening reminders if [isCheckedInToday]; otherwise
  /// (re)schedules whichever of today's 9 PM / 10 PM windows haven't passed
  /// yet. Safe to call repeatedly — always cancels before rescheduling.
  static Future<void> syncCheckinReminders(bool isCheckedInToday) async {
    if (isCheckedInToday) {
      await _plugin.cancel(id: _checkinReminderId);
      await _plugin.cancel(id: _streakAtRiskId);
      return;
    }

    await _scheduleIfUpcoming(
      id: _checkinReminderId,
      hour: 21,
      title: "Don't break the streak! 🔥",
      body: "You haven't checked in today — take a moment to log it.",
    );
    await _scheduleIfUpcoming(
      id: _streakAtRiskId,
      hour: 22,
      title: 'Your streak is at risk ⚠️',
      body: 'Last call — check in now before the day resets.',
    );
  }

  static Future<void> _scheduleIfUpcoming({
    required int id,
    required int hour,
    required String title,
    required String body,
  }) async {
    await _plugin.cancel(id: id);

    final now = tz.TZDateTime.now(tz.local);
    final target = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (target.isBefore(now)) return; // today's window already passed

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: target,
      notificationDetails: const NotificationDetails(android: _reminderChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Fires an immediate celebration if [wallet]'s progress has crossed a new
  /// 25/50/75/100% tier since the last time this wallet was checked. The
  /// last-celebrated tier is persisted in Hive so it survives app restarts
  /// and isn't re-fired on every Realtime update.
  static Future<void> notifyWalletMilestoneIfCrossed(GoalWalletModel wallet) async {
    final box = HiveService.milestonesBox;
    final lastTier = (box.get(wallet.id) as num?)?.toInt() ?? 0;

    final crossed = _milestoneTiers
        .where((tier) => tier > lastTier && wallet.progressPercent >= tier)
        .toList();
    if (crossed.isEmpty) return;

    final newTier = crossed.reduce((a, b) => a > b ? a : b);
    await box.put(wallet.id, newTier);

    await _plugin.show(
      id: wallet.id.hashCode,
      title: newTier == 100 ? 'Goal reached! 🎉' : '$newTier% there! 🎯',
      body: newTier == 100
          ? '"${wallet.goalName}" is fully funded — time to claim it!'
          : 'You\'re $newTier% of the way to "${wallet.goalName}".',
      notificationDetails: const NotificationDetails(android: _milestoneChannel),
    );
  }
}
