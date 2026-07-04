import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_credit_model.freezed.dart';
part 'wallet_credit_model.g.dart';

@freezed
abstract class WalletCreditModel with _$WalletCreditModel {
  const factory WalletCreditModel({
    required String id,
    @JsonKey(name: 'habit_id') required String habitId,
    @JsonKey(name: 'wallet_id') required String walletId,
    required double amount,
    @JsonKey(name: 'credit_date') required DateTime creditDate,
  }) = _WalletCreditModel;

  factory WalletCreditModel.fromJson(Map<String, dynamic> json) =>
      _$WalletCreditModelFromJson(json);
}
