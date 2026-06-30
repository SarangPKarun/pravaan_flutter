import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../habits/models/habit_model.dart';

// ── Per-habit detail ────────────────────────────────────────────────────────

class HabitDetail {
  const HabitDetail({this.dailyQty = 5, this.unitCost = 0.0});

  final int dailyQty;
  final double unitCost;

  double get dailySpend => dailyQty * unitCost;

  HabitDetail copyWith({int? dailyQty, double? unitCost}) => HabitDetail(
        dailyQty: dailyQty ?? this.dailyQty,
        unitCost: unitCost ?? this.unitCost,
      );
}

// ── Data model ──────────────────────────────────────────────────────────────

class OnboardingData {
  const OnboardingData({
    // Personal details (step 0)
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
    this.isUploadingAvatar = false,
    // Habit selection (step 1)
    this.habitTypes = const {},
    this.customHabitName,
    // Habit details (step 2)
    this.habitDetails = const {},
    // Goal (step 3)
    this.savingGoal,
    this.goalTargetDate,
    this.quitDate,
  });

  final String? fullName;
  final DateTime? dateOfBirth;
  // 'male' | 'female' | 'other' | 'prefer_not_to_say'
  final String? gender;
  final String? avatarUrl;
  final bool isUploadingAvatar;

  final Set<HabitType> habitTypes;
  final String? customHabitName;
  final Map<HabitType, HabitDetail> habitDetails;
  final String? savingGoal;
  final DateTime? goalTargetDate;
  final DateTime? quitDate;

  /// First selected habit — used by Step 2/3 for unit/emoji display.
  HabitType? get primaryType =>
      habitTypes.isEmpty ? null : habitTypes.first;

  OnboardingData copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    bool? isUploadingAvatar,
    Set<HabitType>? habitTypes,
    Object? customHabitName = _sentinel,
    Map<HabitType, HabitDetail>? habitDetails,
    Object? savingGoal = _sentinel,
    Object? goalTargetDate = _sentinel,
    Object? quitDate = _sentinel,
  }) {
    return OnboardingData(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      habitTypes: habitTypes ?? this.habitTypes,
      customHabitName: identical(customHabitName, _sentinel)
          ? this.customHabitName
          : customHabitName as String?,
      habitDetails: habitDetails ?? this.habitDetails,
      savingGoal: identical(savingGoal, _sentinel)
          ? this.savingGoal
          : savingGoal as String?,
      goalTargetDate: identical(goalTargetDate, _sentinel)
          ? this.goalTargetDate
          : goalTargetDate as DateTime?,
      quitDate: identical(quitDate, _sentinel)
          ? this.quitDate
          : quitDate as DateTime?,
    );
  }

  // ── Computed savings helpers ────────────────────────────────────────────
  double get dailySpend =>
      habitDetails.values.fold(0.0, (s, d) => s + d.dailySpend);
  double get weeklySavings => dailySpend * 7;
  double get monthlySavings => dailySpend * 30;
  double get sixMonthSavings => dailySpend * 180;
  double get yearlySavings => dailySpend * 365;

  double savingsBy(DateTime to) {
    if (quitDate == null) return 0;
    final days = to.difference(quitDate!).inDays;
    return days > 0 ? days * dailySpend : 0;
  }
}

// Sentinel to distinguish "not passed" from null in copyWith.
const _sentinel = Object();

// ── Notifier ────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  // Personal details
  void setFullName(String name) => state = state.copyWith(fullName: name);
  void setDateOfBirth(DateTime dob) => state = state.copyWith(dateOfBirth: dob);
  void setGender(String gender) => state = state.copyWith(gender: gender);

  Future<void> uploadAvatar(File file) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isUploadingAvatar: true);
    try {
      final bytes = await file.readAsBytes();
      final path = '$userId.jpg';
      await client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final url = client.storage.from('avatars').getPublicUrl(path);
      state = state.copyWith(avatarUrl: url, isUploadingAvatar: false);
    } catch (_) {
      state = state.copyWith(isUploadingAvatar: false);
      rethrow;
    }
  }

  // Habit selection — multi-select toggle
  void toggleHabitType(HabitType type) {
    final current = Set<HabitType>.from(state.habitTypes);
    if (current.contains(type)) {
      current.remove(type);
      if (type == HabitType.custom) {
        state = state.copyWith(habitTypes: current, customHabitName: null);
        return;
      }
    } else {
      current.add(type);
    }
    state = state.copyWith(habitTypes: current);
  }

  void setCustomHabitName(String name) =>
      state = state.copyWith(customHabitName: name.isEmpty ? null : name);

  // Per-habit details
  void setHabitQty(HabitType type, int qty) {
    final details = Map<HabitType, HabitDetail>.from(state.habitDetails);
    details[type] = (details[type] ?? const HabitDetail())
        .copyWith(dailyQty: qty.clamp(1, 100));
    state = state.copyWith(habitDetails: details);
  }

  void setHabitCost(HabitType type, double cost) {
    final details = Map<HabitType, HabitDetail>.from(state.habitDetails);
    details[type] = (details[type] ?? const HabitDetail())
        .copyWith(unitCost: cost.clamp(0.0, 99999.0));
    state = state.copyWith(habitDetails: details);
  }

  void setQuitDate(DateTime date) => state = state.copyWith(quitDate: date);

  void setGoal(String name) {
    final trimmed = name.trim();
    state = state.copyWith(savingGoal: trimmed.isEmpty ? null : trimmed);
  }

  void setGoalTargetDate(DateTime date) =>
      state = state.copyWith(goalTargetDate: date);

  Future<void> complete() async {
    final d = state;
    final quitDate = d.quitDate ?? DateTime.now().toUtc();
    await ref.read(supabaseClientProvider).auth.updateUser(
          UserAttributes(data: {
            'is_onboarded': true,
            'full_name': d.fullName,
            'date_of_birth': d.dateOfBirth?.toIso8601String(),
            'gender': d.gender,
            'avatar_url': d.avatarUrl,
            'habit_types': d.habitTypes.map((t) => t.name).toList(),
            'custom_habit_name': d.customHabitName,
            'habit_details': {
              for (final e in d.habitDetails.entries)
                e.key.name: {
                  'daily_qty': e.value.dailyQty,
                  'unit_cost': e.value.unitCost,
                },
            },
            'quit_date': quitDate.toIso8601String(),
            'saving_goal': d.savingGoal,
            'goal_target_date': d.goalTargetDate?.toIso8601String(),
          }),
        );
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(
  OnboardingNotifier.new,
);
