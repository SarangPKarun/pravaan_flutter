// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HabitModel {

 String get id;@JsonKey(name: 'user_id') String get userId; HabitType get type;@JsonKey(name: 'daily_units') double get dailyUnits;@JsonKey(name: 'cost_per_unit') double get costPerUnit;@JsonKey(name: 'quit_date') DateTime get quitDate;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitModelCopyWith<HabitModel> get copyWith => _$HabitModelCopyWithImpl<HabitModel>(this as HabitModel, _$identity);

  /// Serializes this HabitModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HabitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.dailyUnits, dailyUnits) || other.dailyUnits == dailyUnits)&&(identical(other.costPerUnit, costPerUnit) || other.costPerUnit == costPerUnit)&&(identical(other.quitDate, quitDate) || other.quitDate == quitDate)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,type,dailyUnits,costPerUnit,quitDate,isActive);

@override
String toString() {
  return 'HabitModel(id: $id, userId: $userId, type: $type, dailyUnits: $dailyUnits, costPerUnit: $costPerUnit, quitDate: $quitDate, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $HabitModelCopyWith<$Res>  {
  factory $HabitModelCopyWith(HabitModel value, $Res Function(HabitModel) _then) = _$HabitModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, HabitType type,@JsonKey(name: 'daily_units') double dailyUnits,@JsonKey(name: 'cost_per_unit') double costPerUnit,@JsonKey(name: 'quit_date') DateTime quitDate,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$HabitModelCopyWithImpl<$Res>
    implements $HabitModelCopyWith<$Res> {
  _$HabitModelCopyWithImpl(this._self, this._then);

  final HabitModel _self;
  final $Res Function(HabitModel) _then;

/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? dailyUnits = null,Object? costPerUnit = null,Object? quitDate = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HabitType,dailyUnits: null == dailyUnits ? _self.dailyUnits : dailyUnits // ignore: cast_nullable_to_non_nullable
as double,costPerUnit: null == costPerUnit ? _self.costPerUnit : costPerUnit // ignore: cast_nullable_to_non_nullable
as double,quitDate: null == quitDate ? _self.quitDate : quitDate // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HabitModel].
extension HabitModelPatterns on HabitModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HabitModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HabitModel value)  $default,){
final _that = this;
switch (_that) {
case _HabitModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HabitModel value)?  $default,){
final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  HabitType type, @JsonKey(name: 'daily_units')  double dailyUnits, @JsonKey(name: 'cost_per_unit')  double costPerUnit, @JsonKey(name: 'quit_date')  DateTime quitDate, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.dailyUnits,_that.costPerUnit,_that.quitDate,_that.isActive);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  HabitType type, @JsonKey(name: 'daily_units')  double dailyUnits, @JsonKey(name: 'cost_per_unit')  double costPerUnit, @JsonKey(name: 'quit_date')  DateTime quitDate, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _HabitModel():
return $default(_that.id,_that.userId,_that.type,_that.dailyUnits,_that.costPerUnit,_that.quitDate,_that.isActive);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  HabitType type, @JsonKey(name: 'daily_units')  double dailyUnits, @JsonKey(name: 'cost_per_unit')  double costPerUnit, @JsonKey(name: 'quit_date')  DateTime quitDate, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.dailyUnits,_that.costPerUnit,_that.quitDate,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HabitModel extends HabitModel {
  const _HabitModel({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.type, @JsonKey(name: 'daily_units') required this.dailyUnits, @JsonKey(name: 'cost_per_unit') required this.costPerUnit, @JsonKey(name: 'quit_date') required this.quitDate, @JsonKey(name: 'is_active') required this.isActive}): super._();
  factory _HabitModel.fromJson(Map<String, dynamic> json) => _$HabitModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  HabitType type;
@override@JsonKey(name: 'daily_units') final  double dailyUnits;
@override@JsonKey(name: 'cost_per_unit') final  double costPerUnit;
@override@JsonKey(name: 'quit_date') final  DateTime quitDate;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitModelCopyWith<_HabitModel> get copyWith => __$HabitModelCopyWithImpl<_HabitModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HabitModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HabitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.dailyUnits, dailyUnits) || other.dailyUnits == dailyUnits)&&(identical(other.costPerUnit, costPerUnit) || other.costPerUnit == costPerUnit)&&(identical(other.quitDate, quitDate) || other.quitDate == quitDate)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,type,dailyUnits,costPerUnit,quitDate,isActive);

@override
String toString() {
  return 'HabitModel(id: $id, userId: $userId, type: $type, dailyUnits: $dailyUnits, costPerUnit: $costPerUnit, quitDate: $quitDate, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$HabitModelCopyWith<$Res> implements $HabitModelCopyWith<$Res> {
  factory _$HabitModelCopyWith(_HabitModel value, $Res Function(_HabitModel) _then) = __$HabitModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, HabitType type,@JsonKey(name: 'daily_units') double dailyUnits,@JsonKey(name: 'cost_per_unit') double costPerUnit,@JsonKey(name: 'quit_date') DateTime quitDate,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$HabitModelCopyWithImpl<$Res>
    implements _$HabitModelCopyWith<$Res> {
  __$HabitModelCopyWithImpl(this._self, this._then);

  final _HabitModel _self;
  final $Res Function(_HabitModel) _then;

/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? dailyUnits = null,Object? costPerUnit = null,Object? quitDate = null,Object? isActive = null,}) {
  return _then(_HabitModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HabitType,dailyUnits: null == dailyUnits ? _self.dailyUnits : dailyUnits // ignore: cast_nullable_to_non_nullable
as double,costPerUnit: null == costPerUnit ? _self.costPerUnit : costPerUnit // ignore: cast_nullable_to_non_nullable
as double,quitDate: null == quitDate ? _self.quitDate : quitDate // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
