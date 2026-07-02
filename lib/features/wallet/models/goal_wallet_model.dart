import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_wallet_model.freezed.dart';
part 'goal_wallet_model.g.dart';

@freezed
abstract class GoalWalletModel with _$GoalWalletModel {
  const GoalWalletModel._();

  const factory GoalWalletModel({
    required String id,
    @JsonKey(name: 'habit_id') required String habitId,
    @JsonKey(name: 'goal_name') required String goalName,
    @JsonKey(name: 'target_amount') required double targetAmount,
    @JsonKey(name: 'current_balance') required double currentBalance,
    @JsonKey(name: 'target_date') required DateTime targetDate,
    @JsonKey(name: 'is_locked') required bool isLocked,
    @JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,
    @JsonKey(name: 'upi_id') String? upiId,
  }) = _GoalWalletModel;

  double get progressPercent =>
      targetAmount > 0 ? (currentBalance / targetAmount * 100).clamp(0, 100) : 0;

  /// Days remaining until [targetDate], clamped at 0 (never negative) for
  /// display purposes such as a dashboard "days to goal" highlight.
  int get daysRemaining {
    final days = targetDate.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  factory GoalWalletModel.fromJson(Map<String, dynamic> json) =>
      _$GoalWalletModelFromJson(json);
}
