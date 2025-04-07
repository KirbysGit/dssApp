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
import '../services/image_storage_service.dart';

final securityServiceProvider = Provider((ref) => SecurityService(
  gadgetIp: '192.168.8.225',
));

final securityStatusProvider = StateNotifierProvider<SecurityStatusNotifier, SecurityState>((ref) {
  return SecurityStatusNotifier(ref);
});

final detectionLogsProvider = StateNotifierProvider<DetectionLogsNotifier, List<DetectionLog>>((ref) {
  return DetectionLogsNotifier();
});

final gadgetIpProvider = StateProvider<String>((ref) => '192.168.8.225');

class SecurityStatusNotifier extends StateNotifier<SecurityState> {
  final NotificationService _notificationService = NotificationService();
  Timer? _statusCheckTimer;
  Timer? _detectionResetTimer;  // New timer for resetting detection state
  final Ref _ref;

  SecurityStatusNotifier(this._ref) : super(SecurityState.initial()) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _notificationService.initialize(_ref.container);
    _notificationService.startPolling();
    _startPolling();
  }

  void _startPolling() {
    // Initial check
    checkStatus();
    
    // Poll every 2 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      checkStatus();
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _detectionResetTimer?.cancel();  // Cancel the reset timer
    super.dispose();
  }

  Future<void> checkStatus() async {
    try {
      final gadgetIp = _ref.read(gadgetIpProvider);
      
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

        // If this is a new detection, create a log entry and start the reset timer
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

          // Cancel any existing reset timer
          _detectionResetTimer?.cancel();
          
          // Start a new timer to reset the person detected state after 10 seconds
          _detectionResetTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              state = state.copyWith(
                personDetected: false,
                shouldShowNotification: false,
              );
              debugPrint('Person detection state reset after 10 seconds');
            }
          });
        }

        // Only update state if we're not in the middle of a detection timer
        if (_detectionResetTimer == null || !_detectionResetTimer!.isActive || personDetected) {
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void acknowledgeNotification() {
    state = state.copyWith(shouldShowNotification: false);
  }

  void updateWithDetection({
    required bool isPersonDetected,
    required DateTime lastDetectionTime,
    required Map<String, dynamic> detectedCamera,
  }) {
    // Add debounce logic
    if (isPersonDetected && state.personDetected) {
      // If we're already in a detected state, check the time difference
      if (state.lastDetectionTime != null &&
          lastDetectionTime.difference(state.lastDetectionTime!).inSeconds < 10) {
        // Ignore detections that are too close together
        return;
      }
    }

    final bool wasPersonDetectedBefore = state.personDetected;
    final bool shouldNotify = isPersonDetected && 
      (!wasPersonDetectedBefore || 
       (state.lastDetectionTime != null && 
        lastDetectionTime.difference(state.lastDetectionTime!).inSeconds > 10));

    // Cancel any existing reset timer
    _detectionResetTimer?.cancel();

    state = state.copyWith(
      isLoading: false,
      personDetected: isPersonDetected,
      lastDetectionTime: lastDetectionTime,
      cameras: [detectedCamera, ...state.cameras],
      shouldShowNotification: shouldNotify,
      error: null,
    );

    // Start a new timer to reset the person detected state after 10 seconds
    if (isPersonDetected) {
      _detectionResetTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          state = state.copyWith(
            personDetected: false,
            shouldShowNotification: false,
          );
          debugPrint('Person detection state reset after 10 seconds');
        }
      });
    }
  }
}

class DetectionLogsNotifier extends StateNotifier<List<DetectionLog>> {
  static const int maxStoredImages = 10;  // Maximum number of stored images
  final ImageStorageService _imageStorage = ImageStorageService();
  
  DetectionLogsNotifier() : super([]);

  Future<void> loadInitialLogs() async {
    // In the future, we could load from local storage here
    if (state.isEmpty) {
      state = [];
    }
  }

  void addDetectionLog(DetectionLog log) async {
    // Count how many logs have image paths
    final logsWithImages = state.where((l) => l.imagePath != null).length;
    
    if (logsWithImages >= maxStoredImages && log.imagePath != null) {
      // Find the oldest log with an image and delete its image file
      final oldestLogWithImage = state.firstWhere((l) => l.imagePath != null);
      if (oldestLogWithImage.imagePath != null) {
        await _imageStorage.deleteImage(oldestLogWithImage.imagePath!);
      }
      
      final updatedOldestLog = oldestLogWithImage.copyWith(
        imagePath: null,
        imageBytes: null,
      );
      
      // Update the state by replacing the old log
      state = [
        log,  // Add new log at the beginning
        ...state.map((l) => l.id == oldestLogWithImage.id ? updatedOldestLog : l),
      ];
    } else {
      // Just add the new log normally
      state = [log, ...state];
    }
    
    // Clean up any orphaned image files
    final activePaths = state
        .where((log) => log.imagePath != null)
        .map((log) => log.imagePath!)
        .toList();
    await _imageStorage.cleanupOldImages(activePaths);
    
    _saveLogsToStorage();
  }

  Future<DetectionLog> getLogWithImage(String logId) async {
    final log = state.firstWhere((l) => l.id == logId);
    if (log.imagePath != null && log.imageBytes == null) {
      final imageBytes = await _imageStorage.loadImage(log.imagePath!);
      if (imageBytes != null) {
        return log.copyWith(imageBytes: imageBytes);
      }
    }
    return log;
  }

  Future<void> _saveLogsToStorage() async {
    // TODO: Implement persistent storage
    // For now, just log the save operation
    debugPrint('Saving ${state.length} logs to storage');
    debugPrint('Logs with images: ${state.where((l) => l.imagePath != null).length}');
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

  void clearLogs() async {
    // Delete all image files before clearing logs
    for (final log in state) {
      if (log.imagePath != null) {
        await _imageStorage.deleteImage(log.imagePath!);
      }
    }
    state = [];
    _saveLogsToStorage();
  }
}