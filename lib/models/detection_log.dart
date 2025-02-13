import 'package:freezed_annotation/freezed_annotation.dart';

part 'detection_log.freezed.dart';
part 'detection_log.g.dart';

@freezed
class DetectionLog with _$DetectionLog {
  const factory DetectionLog({
    required String id,
    required DateTime timestamp,
    required String cameraName,
    required String cameraUrl,
    String? imageUrl,
    required bool isAcknowledged,
    required bool wasAlarmTriggered,
  }) = _DetectionLog;

  factory DetectionLog.fromJson(Map<String, dynamic> json) =>
      _$DetectionLogFromJson(json);
} 