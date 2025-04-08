// lib/models/security_state.dart

class SecurityState {
  final bool isLoading;                       // Whether The Security State Is Loading. 
  final bool personDetected;                  // Whether A Person Is Detected.
  final List<Map<String, dynamic>> cameras;   // List Of Cameras.
  final DateTime? lastDetectionTime;          // Last Detection Time.
  final String? error;                        // Error Message.
  final bool shouldShowNotification;          // Whether To Show Notification.

  // Constructor For SecurityState.
  SecurityState({
    this.isLoading = false,
    this.personDetected = false,
    this.cameras = const [],
    this.lastDetectionTime,
    this.error,
    this.shouldShowNotification = false,
  });

  // Create Initial SecurityState.
  factory SecurityState.initial() => SecurityState();

  // Copy With SecurityState.
  SecurityState copyWith({
    bool? isLoading,
    bool? personDetected,
    List<Map<String, dynamic>>? cameras,
    DateTime? lastDetectionTime,
    String? error,
    bool? shouldShowNotification,
  }) {
    return SecurityState(
      isLoading: isLoading ?? this.isLoading,
      personDetected: personDetected ?? this.personDetected,
      cameras: cameras ?? this.cameras,
      lastDetectionTime: lastDetectionTime ?? this.lastDetectionTime,
      error: error ?? this.error,
      shouldShowNotification: shouldShowNotification ?? this.shouldShowNotification,
    );
  }
} 