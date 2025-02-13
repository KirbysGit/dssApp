import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/security_device.dart';
import '../services/mock_security_service.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';
import '../models/security_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/detection_log.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  return SecurityStatusNotifier(ref);
});

final detectionLogsProvider = StateNotifierProvider<DetectionLogsNotifier, List<DetectionLog>>((ref) {
  return DetectionLogsNotifier();
});

class SecurityStatusNotifier extends StateNotifier<SecurityState> {
  Timer? _pollingTimer;
  final Ref _ref;

  SecurityStatusNotifier(this._ref) : super(SecurityState(
    isLoading: false,
    personDetected: false,
    lastDetectionTime: null,
    cameras: [],
    shouldShowNotification: false,
  )) {
    _startPolling();
  }

  void _startPolling() {
    // Initial check
    checkStatus();
    
    // Poll every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      checkStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> checkStatus() async {
    try {
      final gadgetIp = '192.168.8.151';
      
      final statusResponse = await http.get(
        Uri.parse('http://$gadgetIp/person_status'),
      ).timeout(const Duration(seconds: 5));

      if (statusResponse.statusCode == 200) {
        final data = jsonDecode(statusResponse.body);
        debugPrint('Received status data: $data');

        final List<Map<String, dynamic>> cameras = 
          (data['cameras'] as List?)?.map((camera) => 
            Map<String, dynamic>.from(camera as Map)
          ).toList() ?? [];

        debugPrint('Parsed cameras: $cameras');

        final bool personDetected = data['personDetected'] ?? false;
        final bool wasPersonDetectedBefore = state.personDetected;
        
        DateTime? lastDetectionTime;
        if (data['lastDetectionTime'] != null) {
          try {
            lastDetectionTime = DateTime.parse(data['lastDetectionTime'].toString());
          } catch (e) {
            debugPrint('Error parsing timestamp: $e');
            lastDetectionTime = DateTime.now();
          }
        }

        final bool shouldNotify = (personDetected && !wasPersonDetectedBefore) ||
          (personDetected && lastDetectionTime != null && 
           lastDetectionTime != state.lastDetectionTime);

        debugPrint('Person detected: $personDetected, Was detected before: $wasPersonDetectedBefore');
        debugPrint('Last detection time: $lastDetectionTime, Current time: ${state.lastDetectionTime}');
        debugPrint('Should show notification: $shouldNotify');

        // If this is a new detection, create a log entry
        if (shouldNotify && cameras.isNotEmpty) {
          final detectedCamera = cameras.first;
          final newLog = DetectionLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: lastDetectionTime ?? DateTime.now(),
            cameraName: detectedCamera['name'] as String? ?? 'Unknown Camera',
            cameraUrl: detectedCamera['url'] as String? ?? '',
            imageUrl: null,
            isAcknowledged: false,
            wasAlarmTriggered: true,
          );
          
          debugPrint('Creating new detection log: ${newLog.toString()}');
          _ref.read(detectionLogsProvider.notifier).addDetectionLog(newLog);
        }

        if (!state.isLoading) {
          state = state.copyWith(
            isLoading: false,
            personDetected: personDetected,
            lastDetectionTime: lastDetectionTime,
            cameras: cameras,
            shouldShowNotification: shouldNotify,
            error: null,
          );
        }
      } else {
        throw Exception('Failed to fetch status: ${statusResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking status: $e');
      if (!state.isLoading) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  void acknowledgeNotification() {
    state = state.copyWith(shouldShowNotification: false);
  }
}

class DetectionLogsNotifier extends StateNotifier<List<DetectionLog>> {
  DetectionLogsNotifier() : super([]);

  Future<void> loadInitialLogs() async {
    // In the future, we could load from local storage here
    if (state.isEmpty) {
      state = [];
    }
  }

  void addDetectionLog(DetectionLog log) {
    state = [log, ...state];
    _saveLogsToStorage(); // Save to persistent storage
  }

  Future<void> _saveLogsToStorage() async {
    // TODO: Implement persistent storage
    // For now, just log the save operation
    debugPrint('Saving ${state.length} logs to storage');
    for (final log in state) {
      debugPrint('Log: ${log.toString()}');
    }
  }

  void acknowledgeLog(String logId) {
    state = [
      for (final log in state)
        if (log.id == logId)
          log.copyWith(isAcknowledged: true)
        else
          log,
    ];
    _saveLogsToStorage();
  }

  void clearLogs() {
    state = [];
    _saveLogsToStorage();
  }
}