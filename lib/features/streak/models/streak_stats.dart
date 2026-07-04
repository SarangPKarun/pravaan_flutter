import '../../../core/local/hive_service.dart';

class StreakStats {
  const StreakStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCleanDays = 0,
    this.lastCheckinDate,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalCleanDays;

  /// Stored as a local date (no time component) so day comparisons are exact.
  final DateTime? lastCheckinDate;

  StreakStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalCleanDays,
    DateTime? lastCheckinDate,
  }) =>
      StreakStats(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalCleanDays: totalCleanDays ?? this.totalCleanDays,
        lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
      );

  Map<String, dynamic> toJson() => {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'total_clean_days': totalCleanDays,
        'last_checkin_date': lastCheckinDate?.toIso8601String(),
      };

  factory StreakStats.fromJson(Map<String, dynamic> json) => StreakStats(
        currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
        totalCleanDays: (json['total_clean_days'] as num?)?.toInt() ?? 0,
        lastCheckinDate: json['last_checkin_date'] != null
            ? DateTime.tryParse(json['last_checkin_date'] as String)
            : null,
      );

  // ── Computed ─────────────────────────────────────────────────────────────

  bool get isCheckedInToday {
    if (lastCheckinDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = lastCheckinDate!;
    return DateTime(last.year, last.month, last.day).isAtSameMomentAs(today);
  }

  // ── Hive helpers ──────────────────────────────────────────────────────────

  static StreakStats fromHive() {
    final raw = HiveService.streakBox.get('stats') as Map?;
    return raw != null
        ? StreakStats.fromJson(Map<String, dynamic>.from(raw))
        : const StreakStats();
  }

  void saveToHive() => HiveService.streakBox.put('stats', toJson());
}
