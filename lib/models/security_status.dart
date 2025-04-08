// lib/models/security_status.dart

// Importing Freezed Annotation.
import 'package:freezed_annotation/freezed_annotation.dart';

// Importing Generated Json Serialization Code.
part 'security_status.freezed.dart';
part 'security_status.g.dart';

// Creating The SecurityStatus Model.
@freezed
class SecurityStatus with _$SecurityStatus {
  const factory SecurityStatus({
    required bool personDetected,                 // Whether A Person Is Detected.
    required List<Map<String, dynamic>> cameras,  // List Of Cameras.
    DateTime? lastDetectionTime,                  // Last Detection Time.
  }) = _SecurityStatus;

  // Create SecurityStatus From JSON.
  factory SecurityStatus.fromJson(Map<String, dynamic> json) => _$SecurityStatusFromJson(json);
} 