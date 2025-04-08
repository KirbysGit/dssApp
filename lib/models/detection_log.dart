// lib/models/detection_log.dart

// Importing Freezed & Dart Typed Data & Convert Packages.
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data';
import 'dart:convert';

// Importing Freezed Annotation.  
part 'detection_log.freezed.dart';

// Importing Generated Json Serialization Code.
part 'detection_log.g.dart';

// Creating The DetectionLog Model.
@freezed
class DetectionLog with _$DetectionLog {
  const factory DetectionLog({
    required String id,                             // Unique Identifier For Detection Log.
    required DateTime timestamp,                    // Timestamp Of The Detection.
    required String cameraName,                     // Name Of The Camera.
    required String cameraUrl,                      // URL Of The Camera.
    String? imageUrl,                               // URL Of The Image.
    @Default(false) bool isAcknowledged,            // Whether The Log Has Been Acknowledged.
    @Default(false) bool wasAlarmTriggered,         // Whether The Alarm Was Triggered.
    String? imagePath,                              // Local File Path Where The Image Is Stored.
    @JsonKey(ignore: true) Uint8List? imageBytes,   // Transient Field, Not Stored In JSON.
  }) = _DetectionLog;

  factory DetectionLog.fromJson(Map<String, dynamic> json) =>
      _$DetectionLogFromJson(json);
}

String? _uint8ListToJson(Uint8List? data) =>
    data != null ? base64Encode(data) : null;

Uint8List? _uint8ListFromJson(String? json) =>
    json != null ? base64Decode(json) : null; 