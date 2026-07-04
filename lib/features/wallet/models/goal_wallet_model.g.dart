// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoalWalletModel _$GoalWalletModelFromJson(Map<String, dynamic> json) =>
    _GoalWalletModel(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      goalName: json['goal_name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      targetDate: DateTime.parse(json['target_date'] as String),
      isLocked: json['is_locked'] as bool,
      withdrawnAt: json['withdrawn_at'] == null
          ? null
          : DateTime.parse(json['withdrawn_at'] as String),
      upiId: json['upi_id'] as String?,
    );

Map<String, dynamic> _$GoalWalletModelToJson(_GoalWalletModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habit_id': instance.habitId,
      'goal_name': instance.goalName,
      'target_amount': instance.targetAmount,
      'current_balance': instance.currentBalance,
      'target_date': instance.targetDate.toIso8601String(),
      'is_locked': instance.isLocked,
      'withdrawn_at': instance.withdrawnAt?.toIso8601String(),
      'upi_id': instance.upiId,
    };
