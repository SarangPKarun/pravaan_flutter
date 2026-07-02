import 'package:hive_flutter/hive_flutter.dart';

abstract class HiveService {
  static const streakBoxName     = 'streak_stats';
  static const pendingBoxName    = 'pending_sync';
  static const milestonesBoxName = 'wallet_milestones';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(streakBoxName);
    await Hive.openBox(pendingBoxName);
    await Hive.openBox(milestonesBoxName);
  }

  static Box get streakBox     => Hive.box(streakBoxName);
  static Box get pendingBox    => Hive.box(pendingBoxName);
  static Box get milestonesBox => Hive.box(milestonesBoxName);
}
