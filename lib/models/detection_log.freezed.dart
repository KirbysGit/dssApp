// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detection_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DetectionLog _$DetectionLogFromJson(Map<String, dynamic> json) {
  return _DetectionLog.fromJson(json);
}

/// @nodoc
mixin _$DetectionLog {
  String get id => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get cameraName => throw _privateConstructorUsedError;
  String get cameraUrl => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  bool get isAcknowledged => throw _privateConstructorUsedError;
  bool get wasAlarmTriggered => throw _privateConstructorUsedError;

  /// Serializes this DetectionLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectionLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectionLogCopyWith<DetectionLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionLogCopyWith<$Res> {
  factory $DetectionLogCopyWith(
          DetectionLog value, $Res Function(DetectionLog) then) =
      _$DetectionLogCopyWithImpl<$Res, DetectionLog>;
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      String cameraName,
      String cameraUrl,
      String? imageUrl,
      bool isAcknowledged,
      bool wasAlarmTriggered});
}

/// @nodoc
class _$DetectionLogCopyWithImpl<$Res, $Val extends DetectionLog>
    implements $DetectionLogCopyWith<$Res> {
  _$DetectionLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectionLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? cameraName = null,
    Object? cameraUrl = null,
    Object? imageUrl = freezed,
    Object? isAcknowledged = null,
    Object? wasAlarmTriggered = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cameraName: null == cameraName
          ? _value.cameraName
          : cameraName // ignore: cast_nullable_to_non_nullable
              as String,
      cameraUrl: null == cameraUrl
          ? _value.cameraUrl
          : cameraUrl // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isAcknowledged: null == isAcknowledged
          ? _value.isAcknowledged
          : isAcknowledged // ignore: cast_nullable_to_non_nullable
              as bool,
      wasAlarmTriggered: null == wasAlarmTriggered
          ? _value.wasAlarmTriggered
          : wasAlarmTriggered // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectionLogImplCopyWith<$Res>
    implements $DetectionLogCopyWith<$Res> {
  factory _$$DetectionLogImplCopyWith(
          _$DetectionLogImpl value, $Res Function(_$DetectionLogImpl) then) =
      __$$DetectionLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      String cameraName,
      String cameraUrl,
      String? imageUrl,
      bool isAcknowledged,
      bool wasAlarmTriggered});
}

/// @nodoc
class __$$DetectionLogImplCopyWithImpl<$Res>
    extends _$DetectionLogCopyWithImpl<$Res, _$DetectionLogImpl>
    implements _$$DetectionLogImplCopyWith<$Res> {
  __$$DetectionLogImplCopyWithImpl(
      _$DetectionLogImpl _value, $Res Function(_$DetectionLogImpl) _then)
      : super(_value, _then);

  /// Create a copy of DetectionLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? cameraName = null,
    Object? cameraUrl = null,
    Object? imageUrl = freezed,
    Object? isAcknowledged = null,
    Object? wasAlarmTriggered = null,
  }) {
    return _then(_$DetectionLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cameraName: null == cameraName
          ? _value.cameraName
          : cameraName // ignore: cast_nullable_to_non_nullable
              as String,
      cameraUrl: null == cameraUrl
          ? _value.cameraUrl
          : cameraUrl // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isAcknowledged: null == isAcknowledged
          ? _value.isAcknowledged
          : isAcknowledged // ignore: cast_nullable_to_non_nullable
              as bool,
      wasAlarmTriggered: null == wasAlarmTriggered
          ? _value.wasAlarmTriggered
          : wasAlarmTriggered // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectionLogImpl implements _DetectionLog {
  const _$DetectionLogImpl(
      {required this.id,
      required this.timestamp,
      required this.cameraName,
      required this.cameraUrl,
      this.imageUrl,
      required this.isAcknowledged,
      required this.wasAlarmTriggered});

  factory _$DetectionLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectionLogImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime timestamp;
  @override
  final String cameraName;
  @override
  final String cameraUrl;
  @override
  final String? imageUrl;
  @override
  final bool isAcknowledged;
  @override
  final bool wasAlarmTriggered;

  @override
  String toString() {
    return 'DetectionLog(id: $id, timestamp: $timestamp, cameraName: $cameraName, cameraUrl: $cameraUrl, imageUrl: $imageUrl, isAcknowledged: $isAcknowledged, wasAlarmTriggered: $wasAlarmTriggered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.cameraName, cameraName) ||
                other.cameraName == cameraName) &&
            (identical(other.cameraUrl, cameraUrl) ||
                other.cameraUrl == cameraUrl) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isAcknowledged, isAcknowledged) ||
                other.isAcknowledged == isAcknowledged) &&
            (identical(other.wasAlarmTriggered, wasAlarmTriggered) ||
                other.wasAlarmTriggered == wasAlarmTriggered));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, timestamp, cameraName,
      cameraUrl, imageUrl, isAcknowledged, wasAlarmTriggered);

  /// Create a copy of DetectionLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionLogImplCopyWith<_$DetectionLogImpl> get copyWith =>
      __$$DetectionLogImplCopyWithImpl<_$DetectionLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectionLogImplToJson(
      this,
    );
  }
}

abstract class _DetectionLog implements DetectionLog {
  const factory _DetectionLog(
      {required final String id,
      required final DateTime timestamp,
      required final String cameraName,
      required final String cameraUrl,
      final String? imageUrl,
      required final bool isAcknowledged,
      required final bool wasAlarmTriggered}) = _$DetectionLogImpl;

  factory _DetectionLog.fromJson(Map<String, dynamic> json) =
      _$DetectionLogImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get timestamp;
  @override
  String get cameraName;
  @override
  String get cameraUrl;
  @override
  String? get imageUrl;
  @override
  bool get isAcknowledged;
  @override
  bool get wasAlarmTriggered;

  /// Create a copy of DetectionLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectionLogImplCopyWith<_$DetectionLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
