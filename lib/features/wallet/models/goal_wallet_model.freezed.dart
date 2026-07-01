// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_wallet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoalWalletModel {

 String get id;@JsonKey(name: 'habit_id') String get habitId;@JsonKey(name: 'goal_name') String get goalName;@JsonKey(name: 'target_amount') double get targetAmount;@JsonKey(name: 'current_balance') double get currentBalance;@JsonKey(name: 'target_date') DateTime get targetDate;@JsonKey(name: 'is_locked') bool get isLocked;@JsonKey(name: 'withdrawn_at') DateTime? get withdrawnAt;@JsonKey(name: 'upi_id') String? get upiId;
/// Create a copy of GoalWalletModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalWalletModelCopyWith<GoalWalletModel> get copyWith => _$GoalWalletModelCopyWithImpl<GoalWalletModel>(this as GoalWalletModel, _$identity);

  /// Serializes this GoalWalletModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalWalletModel&&(identical(other.id, id) || other.id == id)&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.goalName, goalName) || other.goalName == goalName)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.withdrawnAt, withdrawnAt) || other.withdrawnAt == withdrawnAt)&&(identical(other.upiId, upiId) || other.upiId == upiId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,habitId,goalName,targetAmount,currentBalance,targetDate,isLocked,withdrawnAt,upiId);

@override
String toString() {
  return 'GoalWalletModel(id: $id, habitId: $habitId, goalName: $goalName, targetAmount: $targetAmount, currentBalance: $currentBalance, targetDate: $targetDate, isLocked: $isLocked, withdrawnAt: $withdrawnAt, upiId: $upiId)';
}


}

/// @nodoc
abstract mixin class $GoalWalletModelCopyWith<$Res>  {
  factory $GoalWalletModelCopyWith(GoalWalletModel value, $Res Function(GoalWalletModel) _then) = _$GoalWalletModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'habit_id') String habitId,@JsonKey(name: 'goal_name') String goalName,@JsonKey(name: 'target_amount') double targetAmount,@JsonKey(name: 'current_balance') double currentBalance,@JsonKey(name: 'target_date') DateTime targetDate,@JsonKey(name: 'is_locked') bool isLocked,@JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,@JsonKey(name: 'upi_id') String? upiId
});




}
/// @nodoc
class _$GoalWalletModelCopyWithImpl<$Res>
    implements $GoalWalletModelCopyWith<$Res> {
  _$GoalWalletModelCopyWithImpl(this._self, this._then);

  final GoalWalletModel _self;
  final $Res Function(GoalWalletModel) _then;

/// Create a copy of GoalWalletModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? habitId = null,Object? goalName = null,Object? targetAmount = null,Object? currentBalance = null,Object? targetDate = null,Object? isLocked = null,Object? withdrawnAt = freezed,Object? upiId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,goalName: null == goalName ? _self.goalName : goalName // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,targetDate: null == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as DateTime,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,withdrawnAt: freezed == withdrawnAt ? _self.withdrawnAt : withdrawnAt // ignore: cast_nullable_to_non_nullable
as DateTime?,upiId: freezed == upiId ? _self.upiId : upiId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalWalletModel].
extension GoalWalletModelPatterns on GoalWalletModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalWalletModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalWalletModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalWalletModel value)  $default,){
final _that = this;
switch (_that) {
case _GoalWalletModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalWalletModel value)?  $default,){
final _that = this;
switch (_that) {
case _GoalWalletModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'habit_id')  String habitId, @JsonKey(name: 'goal_name')  String goalName, @JsonKey(name: 'target_amount')  double targetAmount, @JsonKey(name: 'current_balance')  double currentBalance, @JsonKey(name: 'target_date')  DateTime targetDate, @JsonKey(name: 'is_locked')  bool isLocked, @JsonKey(name: 'withdrawn_at')  DateTime? withdrawnAt, @JsonKey(name: 'upi_id')  String? upiId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalWalletModel() when $default != null:
return $default(_that.id,_that.habitId,_that.goalName,_that.targetAmount,_that.currentBalance,_that.targetDate,_that.isLocked,_that.withdrawnAt,_that.upiId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'habit_id')  String habitId, @JsonKey(name: 'goal_name')  String goalName, @JsonKey(name: 'target_amount')  double targetAmount, @JsonKey(name: 'current_balance')  double currentBalance, @JsonKey(name: 'target_date')  DateTime targetDate, @JsonKey(name: 'is_locked')  bool isLocked, @JsonKey(name: 'withdrawn_at')  DateTime? withdrawnAt, @JsonKey(name: 'upi_id')  String? upiId)  $default,) {final _that = this;
switch (_that) {
case _GoalWalletModel():
return $default(_that.id,_that.habitId,_that.goalName,_that.targetAmount,_that.currentBalance,_that.targetDate,_that.isLocked,_that.withdrawnAt,_that.upiId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'habit_id')  String habitId, @JsonKey(name: 'goal_name')  String goalName, @JsonKey(name: 'target_amount')  double targetAmount, @JsonKey(name: 'current_balance')  double currentBalance, @JsonKey(name: 'target_date')  DateTime targetDate, @JsonKey(name: 'is_locked')  bool isLocked, @JsonKey(name: 'withdrawn_at')  DateTime? withdrawnAt, @JsonKey(name: 'upi_id')  String? upiId)?  $default,) {final _that = this;
switch (_that) {
case _GoalWalletModel() when $default != null:
return $default(_that.id,_that.habitId,_that.goalName,_that.targetAmount,_that.currentBalance,_that.targetDate,_that.isLocked,_that.withdrawnAt,_that.upiId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoalWalletModel extends GoalWalletModel {
  const _GoalWalletModel({required this.id, @JsonKey(name: 'habit_id') required this.habitId, @JsonKey(name: 'goal_name') required this.goalName, @JsonKey(name: 'target_amount') required this.targetAmount, @JsonKey(name: 'current_balance') required this.currentBalance, @JsonKey(name: 'target_date') required this.targetDate, @JsonKey(name: 'is_locked') required this.isLocked, @JsonKey(name: 'withdrawn_at') this.withdrawnAt, @JsonKey(name: 'upi_id') this.upiId}): super._();
  factory _GoalWalletModel.fromJson(Map<String, dynamic> json) => _$GoalWalletModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'habit_id') final  String habitId;
@override@JsonKey(name: 'goal_name') final  String goalName;
@override@JsonKey(name: 'target_amount') final  double targetAmount;
@override@JsonKey(name: 'current_balance') final  double currentBalance;
@override@JsonKey(name: 'target_date') final  DateTime targetDate;
@override@JsonKey(name: 'is_locked') final  bool isLocked;
@override@JsonKey(name: 'withdrawn_at') final  DateTime? withdrawnAt;
@override@JsonKey(name: 'upi_id') final  String? upiId;

/// Create a copy of GoalWalletModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalWalletModelCopyWith<_GoalWalletModel> get copyWith => __$GoalWalletModelCopyWithImpl<_GoalWalletModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalWalletModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalWalletModel&&(identical(other.id, id) || other.id == id)&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.goalName, goalName) || other.goalName == goalName)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.withdrawnAt, withdrawnAt) || other.withdrawnAt == withdrawnAt)&&(identical(other.upiId, upiId) || other.upiId == upiId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,habitId,goalName,targetAmount,currentBalance,targetDate,isLocked,withdrawnAt,upiId);

@override
String toString() {
  return 'GoalWalletModel(id: $id, habitId: $habitId, goalName: $goalName, targetAmount: $targetAmount, currentBalance: $currentBalance, targetDate: $targetDate, isLocked: $isLocked, withdrawnAt: $withdrawnAt, upiId: $upiId)';
}


}

/// @nodoc
abstract mixin class _$GoalWalletModelCopyWith<$Res> implements $GoalWalletModelCopyWith<$Res> {
  factory _$GoalWalletModelCopyWith(_GoalWalletModel value, $Res Function(_GoalWalletModel) _then) = __$GoalWalletModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'habit_id') String habitId,@JsonKey(name: 'goal_name') String goalName,@JsonKey(name: 'target_amount') double targetAmount,@JsonKey(name: 'current_balance') double currentBalance,@JsonKey(name: 'target_date') DateTime targetDate,@JsonKey(name: 'is_locked') bool isLocked,@JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,@JsonKey(name: 'upi_id') String? upiId
});




}
/// @nodoc
class __$GoalWalletModelCopyWithImpl<$Res>
    implements _$GoalWalletModelCopyWith<$Res> {
  __$GoalWalletModelCopyWithImpl(this._self, this._then);

  final _GoalWalletModel _self;
  final $Res Function(_GoalWalletModel) _then;

/// Create a copy of GoalWalletModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? habitId = null,Object? goalName = null,Object? targetAmount = null,Object? currentBalance = null,Object? targetDate = null,Object? isLocked = null,Object? withdrawnAt = freezed,Object? upiId = freezed,}) {
  return _then(_GoalWalletModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,goalName: null == goalName ? _self.goalName : goalName // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,targetDate: null == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as DateTime,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,withdrawnAt: freezed == withdrawnAt ? _self.withdrawnAt : withdrawnAt // ignore: cast_nullable_to_non_nullable
as DateTime?,upiId: freezed == upiId ? _self.upiId : upiId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
