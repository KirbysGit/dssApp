// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DetectionLogImpl _$$DetectionLogImplFromJson(Map<String, dynamic> json) =>
    _$DetectionLogImpl(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      cameraName: json['cameraName'] as String,
      cameraUrl: json['cameraUrl'] as String,
      imageUrl: json['imageUrl'] as String?,
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      wasAlarmTriggered: json['wasAlarmTriggered'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
    );

Map<String, dynamic> _$$DetectionLogImplToJson(_$DetectionLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'cameraName': instance.cameraName,
      'cameraUrl': instance.cameraUrl,
      'imageUrl': instance.imageUrl,
      'isAcknowledged': instance.isAcknowledged,
      'wasAlarmTriggered': instance.wasAlarmTriggered,
      'imagePath': instance.imagePath,
    };
