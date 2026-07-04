// Static catalog of achievement badges users can unlock.

enum BadgeTriggerCondition { dayCount, savingsAmount, streakLength, custom }

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.triggerCondition,
    required this.thresholdValue,
  });

  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeTriggerCondition triggerCondition;

  /// Interpreted according to [triggerCondition]: a day count, a streak
  /// length, a savings amount, or a custom-logic marker.
  final num thresholdValue;
}

const List<BadgeModel> badges = [
  BadgeModel(
    id: 'first_day',
    name: 'Day One',
    description: 'Complete your first smoke-free day.',
    iconPath: 'assets/icons/badges/first_day.png',
    triggerCondition: BadgeTriggerCondition.dayCount,
    thresholdValue: 1,
  ),
  BadgeModel(
    id: 'week_warrior',
    name: 'Week Warrior',
    description: 'Stay smoke-free for a full week.',
    iconPath: 'assets/icons/badges/week_warrior.png',
    triggerCondition: BadgeTriggerCondition.dayCount,
    thresholdValue: 7,
  ),
  BadgeModel(
    id: 'month_milestone',
    name: 'Month Milestone',
    description: 'Stay smoke-free for a full month.',
    iconPath: 'assets/icons/badges/month_milestone.png',
    triggerCondition: BadgeTriggerCondition.dayCount,
    thresholdValue: 30,
  ),
  BadgeModel(
    id: 'year_legend',
    name: 'Year Legend',
    description: 'Stay smoke-free for a full year.',
    iconPath: 'assets/icons/badges/year_legend.png',
    triggerCondition: BadgeTriggerCondition.dayCount,
    thresholdValue: 365,
  ),
  BadgeModel(
    id: 'streak_starter',
    name: 'Streak Starter',
    description: 'Check in three days in a row.',
    iconPath: 'assets/icons/badges/streak_starter.png',
    triggerCondition: BadgeTriggerCondition.streakLength,
    thresholdValue: 3,
  ),
  BadgeModel(
    id: 'streak_master',
    name: 'Streak Master',
    description: 'Check in thirty days in a row.',
    iconPath: 'assets/icons/badges/streak_master.png',
    triggerCondition: BadgeTriggerCondition.streakLength,
    thresholdValue: 30,
  ),
  BadgeModel(
    id: 'first_saver',
    name: 'First Saver',
    description: 'Save ₹500 in your wallet.',
    iconPath: 'assets/icons/badges/first_saver.png',
    triggerCondition: BadgeTriggerCondition.savingsAmount,
    thresholdValue: 500,
  ),
  BadgeModel(
    id: 'big_saver',
    name: 'Big Saver',
    description: 'Save ₹5,000 in your wallet.',
    iconPath: 'assets/icons/badges/big_saver.png',
    triggerCondition: BadgeTriggerCondition.savingsAmount,
    thresholdValue: 5000,
  ),
  BadgeModel(
    id: 'goal_achiever',
    name: 'Goal Achiever',
    description: 'Complete your first savings goal payout.',
    iconPath: 'assets/icons/badges/goal_achiever.png',
    triggerCondition: BadgeTriggerCondition.custom,
    thresholdValue: 1,
  ),
  BadgeModel(
    id: 'profile_complete',
    name: 'All Set Up',
    description: 'Finish setting up your profile.',
    iconPath: 'assets/icons/badges/profile_complete.png',
    triggerCondition: BadgeTriggerCondition.custom,
    thresholdValue: 1,
  ),
];

BadgeModel? badgeById(String id) {
  for (final badge in badges) {
    if (badge.id == id) return badge;
  }
  return null;
}
