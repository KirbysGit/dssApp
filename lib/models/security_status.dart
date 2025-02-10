import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_status.freezed.dart';
part 'security_status.g.dart';

@freezed
class SecurityStatus with _$SecurityStatus {
  const factory SecurityStatus({
    required bool personDetected,
    required List<Map<String, dynamic>> cameras,
    DateTime? lastDetectionTime,
  }) = _SecurityStatus;

  factory SecurityStatus.fromJson(Map<String, dynamic> json) => _$SecurityStatusFromJson(json);
} 