import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

// ── Data model ──────────────────────────────────────────────────────────────

class OnboardingData {
  const OnboardingData({
    // Personal details (step 0)
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
    this.isUploadingAvatar = false,
    // Habit (steps 1-3)
    this.habitType,
    this.dailyQty = 5,
    this.unitCost = 15.0,
    this.quitDate,
  });

  final String? fullName;
  final DateTime? dateOfBirth;
  // 'male' | 'female' | 'other' | 'prefer_not_to_say'
  final String? gender;
  final String? avatarUrl;
  final bool isUploadingAvatar;

  final String? habitType;
  final int dailyQty;
  final double unitCost;
  final DateTime? quitDate;

  OnboardingData copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    bool? isUploadingAvatar,
    String? habitType,
    int? dailyQty,
    double? unitCost,
    DateTime? quitDate,
  }) {
    return OnboardingData(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      habitType: habitType ?? this.habitType,
      dailyQty: dailyQty ?? this.dailyQty,
      unitCost: unitCost ?? this.unitCost,
      quitDate: quitDate ?? this.quitDate,
    );
  }

  // ── Computed savings helpers ────────────────────────────────────────────
  double get dailySpend => dailyQty * unitCost;
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

  // Habit details
  void setHabitType(String type) => state = state.copyWith(habitType: type);
  void setDailyQty(int qty) =>
      state = state.copyWith(dailyQty: qty.clamp(1, 100));
  void setUnitCost(double cost) =>
      state = state.copyWith(unitCost: cost.clamp(0.0, 99999.0));
  void setQuitDate(DateTime date) => state = state.copyWith(quitDate: date);

  Future<void> complete() async {
    final d = state;
    await ref.read(supabaseClientProvider).auth.updateUser(
          UserAttributes(data: {
            'is_onboarded': true,
            'full_name': d.fullName,
            'date_of_birth': d.dateOfBirth?.toIso8601String(),
            'gender': d.gender,
            'avatar_url': d.avatarUrl,
            'habit_type': d.habitType,
            'daily_qty': d.dailyQty,
            'unit_cost': d.unitCost,
            'quit_date': d.quitDate?.toIso8601String(),
          }),
        );
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(
  OnboardingNotifier.new,
);
