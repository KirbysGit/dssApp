import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/security_device.dart';
import '../services/mock_security_service.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';
import '../models/security_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityProvider with ChangeNotifier {
  final _service = MockSecurityService();
  final _notificationService = NotificationService();
  List<SecurityDevice> _devices = [];
  bool _isSystemArmed = false;
  bool _isLoading = false;
  String? _error;
  bool _personDetected = false;

  SecurityProvider() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
    _notificationService.startPolling();
  }

  bool get isSystemArmed => _isSystemArmed;
  List<SecurityDevice> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get personDetected => _personDetected;

  void toggleSystem() {
    _isSystemArmed = !_isSystemArmed;
    notifyListeners();
  }

  Future<void> refreshDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _service.getDevices();
      for (var device in _devices) {
        final isOnline = await _service.checkDeviceStatus(device.id);
        device.isOnline = isOnline;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationService.stopPolling();
    super.dispose();
  }
}

final securityServiceProvider = Provider((ref) => SecurityService(
  gadgetIp: '192.168.8.151',
));

final securityStatusProvider = StateNotifierProvider<SecurityStatusNotifier, SecurityState>((ref) {
  return SecurityStatusNotifier(ref.watch(securityServiceProvider));
});

class SecurityStatusNotifier extends StateNotifier<SecurityState> {
  final SecurityService _securityService;
  Timer? _statusCheckTimer;
  bool _previousDetectionState = false;

  SecurityStatusNotifier(this._securityService) : super(SecurityState.initial()) {
    _startStatusChecking();
  }

  void _startStatusChecking() {
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => checkStatus(),
    );
  }

  Future<void> checkStatus() async {
    try {
      final status = await _securityService.checkPersonStatus();
      
      // Debug logs for state changes
      debugPrint('Previous detection state: $_previousDetectionState');
      debugPrint('Current detection state: ${status.personDetected}');
      debugPrint('Last detection time: ${status.lastDetectionTime}');
      
      // Check if this is a new detection
      bool isNewDetection = !_previousDetectionState && status.personDetected;
      debugPrint('Is new detection? $isNewDetection');

      if (isNewDetection) {
        debugPrint('New person detected! Triggering notification...');
      }

      _previousDetectionState = status.personDetected;

      state = state.copyWith(
        isLoading: false,
        personDetected: status.personDetected,
        cameras: status.cameras,
        lastDetectionTime: status.lastDetectionTime,
        shouldShowNotification: isNewDetection,
      );

      // Debug log for state update
      debugPrint('Updated state - shouldShowNotification: ${state.shouldShowNotification}');
    } catch (e) {
      debugPrint('Error checking status: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        shouldShowNotification: false,
      );
    }
  }

  void acknowledgeNotification() {
    debugPrint('Acknowledging notification');
    if (state.shouldShowNotification) {
      state = state.copyWith(shouldShowNotification: false);
      debugPrint('Notification acknowledged, shouldShowNotification set to false');
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }
}