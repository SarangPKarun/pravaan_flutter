import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_model.freezed.dart';
part 'habit_model.g.dart';

enum HabitType {
  @JsonValue('cigarette') cigarette,
  @JsonValue('alcohol') alcohol,
  @JsonValue('gutka') gutka,
  @JsonValue('junk_food') junkFood,
  @JsonValue('gambling') gambling,
  @JsonValue('custom') custom,
}

@freezed
abstract class HabitModel with _$HabitModel {
  const HabitModel._();

  const factory HabitModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required HabitType type,
    @JsonKey(name: 'daily_units') required double dailyUnits,
    @JsonKey(name: 'cost_per_unit') required double costPerUnit,
    @JsonKey(name: 'quit_date') required DateTime quitDate,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _HabitModel;

  double get dailySpend => dailyUnits * costPerUnit;

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);
}
