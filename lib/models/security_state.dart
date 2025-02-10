class SecurityState {
  final bool isLoading;
  final bool personDetected;
  final List<Map<String, dynamic>> cameras;
  final DateTime? lastDetectionTime;
  final String? error;
  final bool shouldShowNotification;

  SecurityState({
    this.isLoading = false,
    this.personDetected = false,
    this.cameras = const [],
    this.lastDetectionTime,
    this.error,
    this.shouldShowNotification = false,
  });

  factory SecurityState.initial() => SecurityState();

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