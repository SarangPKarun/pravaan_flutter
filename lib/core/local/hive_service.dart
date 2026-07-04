import 'package:hive_flutter/hive_flutter.dart';

abstract class HiveService {
  static const streakBoxName     = 'streak_stats';
  static const pendingBoxName    = 'pending_sync';
  static const milestonesBoxName = 'wallet_milestones';
  static const badgesBoxName     = 'earned_badges';
  static const settingsBoxName   = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(streakBoxName);
    await Hive.openBox(pendingBoxName);
    await Hive.openBox(milestonesBoxName);
    await Hive.openBox(badgesBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box get streakBox     => Hive.box(streakBoxName);
  static Box get pendingBox    => Hive.box(pendingBoxName);
  static Box get milestonesBox => Hive.box(milestonesBoxName);
  static Box get badgesBox     => Hive.box(badgesBoxName);
  static Box get settingsBox   => Hive.box(settingsBoxName);
}
