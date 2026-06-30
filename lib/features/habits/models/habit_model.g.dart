// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HabitModel _$HabitModelFromJson(Map<String, dynamic> json) => _HabitModel(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  type: $enumDecode(_$HabitTypeEnumMap, json['type']),
  dailyUnits: (json['daily_units'] as num).toDouble(),
  costPerUnit: (json['cost_per_unit'] as num).toDouble(),
  quitDate: DateTime.parse(json['quit_date'] as String),
  isActive: json['is_active'] as bool,
);

Map<String, dynamic> _$HabitModelToJson(_HabitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': _$HabitTypeEnumMap[instance.type]!,
      'daily_units': instance.dailyUnits,
      'cost_per_unit': instance.costPerUnit,
      'quit_date': instance.quitDate.toIso8601String(),
      'is_active': instance.isActive,
    };

const _$HabitTypeEnumMap = {
  HabitType.cigarette: 'cigarette',
  HabitType.alcohol: 'alcohol',
  HabitType.gutka: 'gutka',
  HabitType.junkFood: 'junk_food',
  HabitType.gambling: 'gambling',
  HabitType.custom: 'custom',
};
