// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_credit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletCreditModel {

 String get id;@JsonKey(name: 'habit_id') String get habitId;@JsonKey(name: 'wallet_id') String get walletId; double get amount;@JsonKey(name: 'credit_date') DateTime get creditDate;
/// Create a copy of WalletCreditModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletCreditModelCopyWith<WalletCreditModel> get copyWith => _$WalletCreditModelCopyWithImpl<WalletCreditModel>(this as WalletCreditModel, _$identity);

  /// Serializes this WalletCreditModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletCreditModel&&(identical(other.id, id) || other.id == id)&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.creditDate, creditDate) || other.creditDate == creditDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,habitId,walletId,amount,creditDate);

@override
String toString() {
  return 'WalletCreditModel(id: $id, habitId: $habitId, walletId: $walletId, amount: $amount, creditDate: $creditDate)';
}


}

/// @nodoc
abstract mixin class $WalletCreditModelCopyWith<$Res>  {
  factory $WalletCreditModelCopyWith(WalletCreditModel value, $Res Function(WalletCreditModel) _then) = _$WalletCreditModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'habit_id') String habitId,@JsonKey(name: 'wallet_id') String walletId, double amount,@JsonKey(name: 'credit_date') DateTime creditDate
});




}
/// @nodoc
class _$WalletCreditModelCopyWithImpl<$Res>
    implements $WalletCreditModelCopyWith<$Res> {
  _$WalletCreditModelCopyWithImpl(this._self, this._then);

  final WalletCreditModel _self;
  final $Res Function(WalletCreditModel) _then;

/// Create a copy of WalletCreditModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? habitId = null,Object? walletId = null,Object? amount = null,Object? creditDate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,creditDate: null == creditDate ? _self.creditDate : creditDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletCreditModel].
extension WalletCreditModelPatterns on WalletCreditModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletCreditModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletCreditModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletCreditModel value)  $default,){
final _that = this;
switch (_that) {
case _WalletCreditModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletCreditModel value)?  $default,){
final _that = this;
switch (_that) {
case _WalletCreditModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'habit_id')  String habitId, @JsonKey(name: 'wallet_id')  String walletId,  double amount, @JsonKey(name: 'credit_date')  DateTime creditDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletCreditModel() when $default != null:
return $default(_that.id,_that.habitId,_that.walletId,_that.amount,_that.creditDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'habit_id')  String habitId, @JsonKey(name: 'wallet_id')  String walletId,  double amount, @JsonKey(name: 'credit_date')  DateTime creditDate)  $default,) {final _that = this;
switch (_that) {
case _WalletCreditModel():
return $default(_that.id,_that.habitId,_that.walletId,_that.amount,_that.creditDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'habit_id')  String habitId, @JsonKey(name: 'wallet_id')  String walletId,  double amount, @JsonKey(name: 'credit_date')  DateTime creditDate)?  $default,) {final _that = this;
switch (_that) {
case _WalletCreditModel() when $default != null:
return $default(_that.id,_that.habitId,_that.walletId,_that.amount,_that.creditDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletCreditModel implements WalletCreditModel {
  const _WalletCreditModel({required this.id, @JsonKey(name: 'habit_id') required this.habitId, @JsonKey(name: 'wallet_id') required this.walletId, required this.amount, @JsonKey(name: 'credit_date') required this.creditDate});
  factory _WalletCreditModel.fromJson(Map<String, dynamic> json) => _$WalletCreditModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'habit_id') final  String habitId;
@override@JsonKey(name: 'wallet_id') final  String walletId;
@override final  double amount;
@override@JsonKey(name: 'credit_date') final  DateTime creditDate;

/// Create a copy of WalletCreditModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletCreditModelCopyWith<_WalletCreditModel> get copyWith => __$WalletCreditModelCopyWithImpl<_WalletCreditModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletCreditModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletCreditModel&&(identical(other.id, id) || other.id == id)&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.creditDate, creditDate) || other.creditDate == creditDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,habitId,walletId,amount,creditDate);

@override
String toString() {
  return 'WalletCreditModel(id: $id, habitId: $habitId, walletId: $walletId, amount: $amount, creditDate: $creditDate)';
}


}

/// @nodoc
abstract mixin class _$WalletCreditModelCopyWith<$Res> implements $WalletCreditModelCopyWith<$Res> {
  factory _$WalletCreditModelCopyWith(_WalletCreditModel value, $Res Function(_WalletCreditModel) _then) = __$WalletCreditModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'habit_id') String habitId,@JsonKey(name: 'wallet_id') String walletId, double amount,@JsonKey(name: 'credit_date') DateTime creditDate
});




}
/// @nodoc
class __$WalletCreditModelCopyWithImpl<$Res>
    implements _$WalletCreditModelCopyWith<$Res> {
  __$WalletCreditModelCopyWithImpl(this._self, this._then);

  final _WalletCreditModel _self;
  final $Res Function(_WalletCreditModel) _then;

/// Create a copy of WalletCreditModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? habitId = null,Object? walletId = null,Object? amount = null,Object? creditDate = null,}) {
  return _then(_WalletCreditModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,creditDate: null == creditDate ? _self.creditDate : creditDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
