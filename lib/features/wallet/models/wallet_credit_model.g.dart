// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_credit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletCreditModel _$WalletCreditModelFromJson(Map<String, dynamic> json) =>
    _WalletCreditModel(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      walletId: json['wallet_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      creditDate: DateTime.parse(json['credit_date'] as String),
    );

Map<String, dynamic> _$WalletCreditModelToJson(_WalletCreditModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habit_id': instance.habitId,
      'wallet_id': instance.walletId,
      'amount': instance.amount,
      'credit_date': instance.creditDate.toIso8601String(),
    };
