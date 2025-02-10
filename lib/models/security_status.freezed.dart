// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SecurityStatus _$SecurityStatusFromJson(Map<String, dynamic> json) {
  return _SecurityStatus.fromJson(json);
}

/// @nodoc
mixin _$SecurityStatus {
  bool get personDetected => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get cameras => throw _privateConstructorUsedError;
  DateTime? get lastDetectionTime => throw _privateConstructorUsedError;

  /// Serializes this SecurityStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SecurityStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SecurityStatusCopyWith<SecurityStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SecurityStatusCopyWith<$Res> {
  factory $SecurityStatusCopyWith(
          SecurityStatus value, $Res Function(SecurityStatus) then) =
      _$SecurityStatusCopyWithImpl<$Res, SecurityStatus>;
  @useResult
  $Res call(
      {bool personDetected,
      List<Map<String, dynamic>> cameras,
      DateTime? lastDetectionTime});
}

/// @nodoc
class _$SecurityStatusCopyWithImpl<$Res, $Val extends SecurityStatus>
    implements $SecurityStatusCopyWith<$Res> {
  _$SecurityStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SecurityStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? personDetected = null,
    Object? cameras = null,
    Object? lastDetectionTime = freezed,
  }) {
    return _then(_value.copyWith(
      personDetected: null == personDetected
          ? _value.personDetected
          : personDetected // ignore: cast_nullable_to_non_nullable
              as bool,
      cameras: null == cameras
          ? _value.cameras
          : cameras // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      lastDetectionTime: freezed == lastDetectionTime
          ? _value.lastDetectionTime
          : lastDetectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SecurityStatusImplCopyWith<$Res>
    implements $SecurityStatusCopyWith<$Res> {
  factory _$$SecurityStatusImplCopyWith(_$SecurityStatusImpl value,
          $Res Function(_$SecurityStatusImpl) then) =
      __$$SecurityStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool personDetected,
      List<Map<String, dynamic>> cameras,
      DateTime? lastDetectionTime});
}

/// @nodoc
class __$$SecurityStatusImplCopyWithImpl<$Res>
    extends _$SecurityStatusCopyWithImpl<$Res, _$SecurityStatusImpl>
    implements _$$SecurityStatusImplCopyWith<$Res> {
  __$$SecurityStatusImplCopyWithImpl(
      _$SecurityStatusImpl _value, $Res Function(_$SecurityStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of SecurityStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? personDetected = null,
    Object? cameras = null,
    Object? lastDetectionTime = freezed,
  }) {
    return _then(_$SecurityStatusImpl(
      personDetected: null == personDetected
          ? _value.personDetected
          : personDetected // ignore: cast_nullable_to_non_nullable
              as bool,
      cameras: null == cameras
          ? _value._cameras
          : cameras // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      lastDetectionTime: freezed == lastDetectionTime
          ? _value.lastDetectionTime
          : lastDetectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SecurityStatusImpl implements _SecurityStatus {
  const _$SecurityStatusImpl(
      {required this.personDetected,
      required final List<Map<String, dynamic>> cameras,
      this.lastDetectionTime})
      : _cameras = cameras;

  factory _$SecurityStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$SecurityStatusImplFromJson(json);

  @override
  final bool personDetected;
  final List<Map<String, dynamic>> _cameras;
  @override
  List<Map<String, dynamic>> get cameras {
    if (_cameras is EqualUnmodifiableListView) return _cameras;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cameras);
  }

  @override
  final DateTime? lastDetectionTime;

  @override
  String toString() {
    return 'SecurityStatus(personDetected: $personDetected, cameras: $cameras, lastDetectionTime: $lastDetectionTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SecurityStatusImpl &&
            (identical(other.personDetected, personDetected) ||
                other.personDetected == personDetected) &&
            const DeepCollectionEquality().equals(other._cameras, _cameras) &&
            (identical(other.lastDetectionTime, lastDetectionTime) ||
                other.lastDetectionTime == lastDetectionTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, personDetected,
      const DeepCollectionEquality().hash(_cameras), lastDetectionTime);

  /// Create a copy of SecurityStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SecurityStatusImplCopyWith<_$SecurityStatusImpl> get copyWith =>
      __$$SecurityStatusImplCopyWithImpl<_$SecurityStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SecurityStatusImplToJson(
      this,
    );
  }
}

abstract class _SecurityStatus implements SecurityStatus {
  const factory _SecurityStatus(
      {required final bool personDetected,
      required final List<Map<String, dynamic>> cameras,
      final DateTime? lastDetectionTime}) = _$SecurityStatusImpl;

  factory _SecurityStatus.fromJson(Map<String, dynamic> json) =
      _$SecurityStatusImpl.fromJson;

  @override
  bool get personDetected;
  @override
  List<Map<String, dynamic>> get cameras;
  @override
  DateTime? get lastDetectionTime;

  /// Create a copy of SecurityStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SecurityStatusImplCopyWith<_$SecurityStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
