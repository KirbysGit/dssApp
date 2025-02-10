// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SecurityStatusImpl _$$SecurityStatusImplFromJson(Map<String, dynamic> json) =>
    _$SecurityStatusImpl(
      personDetected: json['personDetected'] as bool,
      cameras: (json['cameras'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      lastDetectionTime: json['lastDetectionTime'] == null
          ? null
          : DateTime.parse(json['lastDetectionTime'] as String),
    );

Map<String, dynamic> _$$SecurityStatusImplToJson(
        _$SecurityStatusImpl instance) =>
    <String, dynamic>{
      'personDetected': instance.personDetected,
      'cameras': instance.cameras,
      'lastDetectionTime': instance.lastDetectionTime?.toIso8601String(),
    };
