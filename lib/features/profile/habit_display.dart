import '../habits/models/habit_model.dart';

/// Display metadata for a habit type, keyed directly by the enum — avoids
/// relying on any particular string casing (the `habit_types`/`habit_details`
/// user-metadata onboarding writes uses `HabitType.name`, e.g. `'junkFood'`,
/// not the snake_case `@JsonValue` used elsewhere in this codebase).
class HabitDisplayInfo {
  const HabitDisplayInfo({required this.emoji, required this.label, required this.unit});

  final String emoji;
  final String label;
  final String unit;
}

const habitDisplayInfo = {
  HabitType.cigarette: HabitDisplayInfo(emoji: '🚬', label: 'Cigarettes', unit: 'cigarettes'),
  HabitType.alcohol: HabitDisplayInfo(emoji: '🍺', label: 'Alcohol', unit: 'drinks'),
  HabitType.gutka: HabitDisplayInfo(emoji: '🟤', label: 'Gutka', unit: 'pieces'),
  HabitType.junkFood: HabitDisplayInfo(emoji: '🍔', label: 'Junk Food', unit: 'servings'),
  HabitType.gambling: HabitDisplayInfo(emoji: '🎰', label: 'Gambling', unit: 'sessions'),
  HabitType.custom: HabitDisplayInfo(emoji: '🔥', label: 'Custom', unit: 'units'),
};

/// Parses the `habit_types` user-metadata list (written as `HabitType.name`
/// strings by onboarding) back into enum values, dropping anything unknown.
List<HabitType> parseHabitTypes(Object? raw) {
  final nameMap = HabitType.values.asNameMap();
  return (raw is List ? raw : const [])
      .whereType<String>()
      .map((name) => nameMap[name])
      .whereType<HabitType>()
      .toList();
}

typedef HabitDetail = ({int dailyQty, double unitCost});

/// Parses the `habit_details` user-metadata map (keyed by `HabitType.name`)
/// into `{dailyQty, unitCost}` per habit, defaulting missing values to zero.
Map<HabitType, HabitDetail> parseHabitDetails(Object? raw) {
  final map = raw is Map ? raw : const {};
  final nameMap = HabitType.values.asNameMap();
  final result = <HabitType, HabitDetail>{};
  for (final entry in map.entries) {
    final type = nameMap[entry.key as String];
    if (type == null) continue;
    final detail = entry.value as Map?;
    result[type] = (
      dailyQty: (detail?['daily_qty'] as num?)?.toInt() ?? 0,
      unitCost: (detail?['unit_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
  return result;
}
