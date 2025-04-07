import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data';
import 'dart:convert';

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
    @Default(false) bool isAcknowledged,
    @Default(false) bool wasAlarmTriggered,
    String? imagePath,  // Local file path where the image is stored
    @JsonKey(ignore: true) Uint8List? imageBytes,  // Transient field, not stored in JSON
  }) = _DetectionLog;

  factory DetectionLog.fromJson(Map<String, dynamic> json) =>
      _$DetectionLogFromJson(json);
}

String? _uint8ListToJson(Uint8List? data) =>
    data != null ? base64Encode(data) : null;

Uint8List? _uint8ListFromJson(String? json) =>
    json != null ? base64Decode(json) : null; 