// lib/providers/security_provider.dart

// Description :
// This file contains the providers for the security system.
// It provides the state and notifiers for the security system.
// It also provides the providers for the security devices and cameras.
// It also provides the providers for the security status and detection logs.

// Importing Required Packages.
import 'dart:async';
import 'dart:convert';
import '../models/detection_log.dart';
import '../models/security_state.dart';
import 'package:http/http.dart' as http;
import '../services/security_service.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/image_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Basic configuration provider with default IP
final gadgetIpProvider = StateProvider<String>((ref) => '192.168.8.207');

final securityServiceProvider = Provider((ref) => SecurityService(
  gadgetIp: ref.watch(gadgetIpProvider),
));

// Security Status Provider.
final securityStatusProvider = StateNotifierProvider<SecurityStatusNotifier, SecurityState>((ref) {
  return SecurityStatusNotifier(ref);
});

// Detection Logs Provider.
final detectionLogsProvider = StateNotifierProvider<DetectionLogsNotifier, List<DetectionLog>>((ref) {
  return DetectionLogsNotifier();
});

// Security Status Notifier.
class SecurityStatusNotifier extends StateNotifier<SecurityState> {
  final NotificationService _notificationService = NotificationService(); // Notification Service.
  Timer? _statusCheckTimer; // Status Check Timer.
  Timer? _detectionResetTimer; // Detection Reset Timer.
  final Ref _ref; // Reference To The Ref Object.

  // Constructor For SecurityStatusNotifier.
  SecurityStatusNotifier(this._ref) : super(SecurityState.initial()) {
    _initializeServices();
  }

  // Initialize Services.
  Future<void> _initializeServices() async {
    _notificationService.initialize(_ref.container);
    _startPolling();
  }

  // Start Polling.
  void _startPolling() {
    // Initial Check.
    checkStatus();
    
    // Poll Every 2 Seconds.
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      checkStatus();
    });
  }

  // Dispose.
  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _detectionResetTimer?.cancel();  // Cancel The Reset Timer.
    super.dispose();
  }

  // Check Status.
  Future<void> checkStatus() async {
    try {
      // Read The Gadget IP.
      final gadgetIp = _ref.read(gadgetIpProvider);
      
      // Get The Status Response.
      final statusResponse = await http.get(
        Uri.parse('http://$gadgetIp/person_status'),
      ).timeout(const Duration(seconds: 5));

      // If The Status Response Is 200.
      if (statusResponse.statusCode == 200) {
        // Decode The Status Response.
        final data = jsonDecode(statusResponse.body);
        //debugPrint('Received status data: $data');

        // Parse The Cameras.
        final List<Map<String, dynamic>> cameras = 
          (data['cameras'] as List?)?.map((camera) => 
            Map<String, dynamic>.from(camera as Map)
          ).toList() ?? [];

        // Debug Print The Parsed Cameras.
        //debugPrint('Parsed cameras: $cameras');

        // Parse The Person Detected.
        final bool personDetected = data['personDetected'] ?? false;
        final bool wasPersonDetectedBefore = state.personDetected;

        // Parse The Last Detection Time.
        DateTime? lastDetectionTime;
        if (data['lastDetectionTime'] != null) {
          try {
            lastDetectionTime = DateTime.parse(data['lastDetectionTime'].toString());
          } catch (e) {
            //debugPrint('Error parsing timestamp: $e');
            lastDetectionTime = DateTime.now();
          }
        }

        // Parse The Should Notify.
        final bool shouldNotify = (personDetected && !wasPersonDetectedBefore) ||
          (personDetected && lastDetectionTime != null && 
           lastDetectionTime != state.lastDetectionTime);

        // Only log when there's a detection or notification event
        if (personDetected || shouldNotify) {
          debugPrint('\n🔍 Detection Event:');
          debugPrint('├─ Person Detected: $personDetected');
          debugPrint('├─ Was Previously Detected: $wasPersonDetectedBefore');
          debugPrint('├─ Detection Time: $lastDetectionTime');
          debugPrint('└─ Should Notify: $shouldNotify\n');
        }

        // If This Is A New Detection, Create A Log Entry And Start The Reset Timer.
        if (shouldNotify && cameras.isNotEmpty) {
          debugPrint('📝 Creating new detection log entry for camera: ${cameras.first['name']}');
          _handleNewDetection(cameras.first, lastDetectionTime);
        }

        // Only Update State If We're Not In The Middle Of A Detection Timer.
        if (_detectionResetTimer == null || !_detectionResetTimer!.isActive || personDetected) {
          if (personDetected || shouldNotify) {
            debugPrint('🔄 Updating security state with new detection data');
          }
          _updateState(personDetected, lastDetectionTime, cameras, shouldNotify);
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

  // Handle New Detection.
  void _handleNewDetection(Map<String, dynamic> detectedCamera, DateTime? timestamp) {
    final newLog = DetectionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),               // Unique ID For The Log.
      timestamp: timestamp ?? DateTime.now(),                             // Timestamp Of The Detection.
      cameraName: detectedCamera['name'] as String? ?? 'Unknown Camera',  // Name Of The Camera.
      cameraUrl: detectedCamera['url'] as String? ?? '',                  // URL Of The Camera.
      imageUrl: null,                                                     // URL Of The Image.
      isAcknowledged: false,                                              // Whether The Log Has Been Acknowledged.
      wasAlarmTriggered: true,                                            // Whether The Alarm Was Triggered.
    );
    
    _ref.read(detectionLogsProvider.notifier).addDetectionLog(newLog); // Add The Log To The Detection Logs.
    _resetDetectionTimer(); // Reset The Detection Timer.
  }

  // Update State.
  void _updateState(bool detected, DateTime? timestamp, List<Map<String, dynamic>> cameras, bool notify) {
    if (_detectionResetTimer == null || !_detectionResetTimer!.isActive || detected) {
      state = state.copyWith(
        isLoading: false,                 // Whether The State Is Loading.
        personDetected: detected,         // Whether The Person Is Detected.
        lastDetectionTime: timestamp,     // Last Detection Time.
        cameras: cameras,                 // Cameras.
        shouldShowNotification: notify,   // Whether To Show Notification.
        error: null,                      // Error.
      );
    }
  }

  // Reset Detection Timer.
  void _resetDetectionTimer() {
    _detectionResetTimer?.cancel();
    _detectionResetTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        debugPrint('\n🕒 Detection state reset:');
        debugPrint('├─ Clearing person detected state');
        debugPrint('└─ Resetting notification flag\n');
        
        state = state.copyWith(
          personDetected: false,          // Whether The Person Is Detected.
          shouldShowNotification: false,  // Whether To Show Notification.
        );
      }
    });
  }

  // Acknowledge Notification.  
  void acknowledgeNotification() {
    state = state.copyWith(shouldShowNotification: false); // Acknowledge The Notification.
  }

  // Update With Detection.
  void updateWithDetection({
    required bool isPersonDetected,               // Whether The Person Is Detected.
    required DateTime lastDetectionTime,          // Last Detection Time.
    required Map<String, dynamic> detectedCamera, // Detected Camera.
  }) {
    // Add Debounce Logic.
    if (isPersonDetected && state.personDetected) {
      // If We're Already In A Detected State, Check The Time Difference.
      if (state.lastDetectionTime != null &&
          lastDetectionTime.difference(state.lastDetectionTime!).inSeconds < 10) {
        // Ignore Detections That Are Too Close Together.
        return;
      }
    }

    // Parse The Was Person Detected Before.
    final bool wasPersonDetectedBefore = state.personDetected;

    // Parse The Should Notify.
    final bool shouldNotify = isPersonDetected && 
      (!wasPersonDetectedBefore || 
       (state.lastDetectionTime != null && 
        lastDetectionTime.difference(state.lastDetectionTime!).inSeconds > 10));

    // Cancel Any Existing Reset Timer.
    _detectionResetTimer?.cancel();

    state = state.copyWith(
      isLoading: false,
      personDetected: isPersonDetected,
      lastDetectionTime: lastDetectionTime,
      cameras: [detectedCamera, ...state.cameras],
      shouldShowNotification: shouldNotify,
      error: null,
    );

    // Start A New Timer To Reset The Person Detected State After 10 Seconds.
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

// Creating The DetectionLogsNotifier.
class DetectionLogsNotifier extends StateNotifier<List<DetectionLog>> {
  static const int maxStoredImages = 10;    // Maximum Number Of Stored Images.
  static const int maxStoredLogs = 20;      // Maximum Number Of Stored Logs.
  final ImageStorageService _imageStorage = ImageStorageService(); // Image Storage Service.

  // Constructor For DetectionLogsNotifier.
  DetectionLogsNotifier() : super([]);

  // Load Initial Logs.
  Future<void> loadInitialLogs() async {
    // In The Future, We Could Load From Local Storage Here.
    if (state.isEmpty) {
      state = [];
    }
  }

  // Add Detection Log.
  void addDetectionLog(DetectionLog log) async {
    // If We've Reached The Max Logs Limit, Remove The Oldest Log.
    if (state.length >= maxStoredLogs) {
      _removeOldestLog();
    }

    // Count How Many Logs Have Image Paths.
    final logsWithImages = state.where((l) => l.imagePath != null).length;
    
    if (logsWithImages >= maxStoredImages && log.imagePath != null) {
      _handleImageLimitExceeded(log);
    } else {
      // Just Add The New Log Normally.
      state = [log, ...state];
    }
    
    // Clean Up Any Orphaned Image Files.
    await _cleanupImages();
  }

  // Remove Oldest Log.
  void _removeOldestLog() async {
    final oldestLog = state.last; // Oldest Log.
    if (oldestLog.imagePath != null) {
      await _imageStorage.deleteImage(oldestLog.imagePath!);
    }
    state = state.sublist(0, state.length - 1);
  }

  // Handle Image Limit Exceeded.
  void _handleImageLimitExceeded(DetectionLog newLog) async {
    final oldestLogWithImage = state.firstWhere((l) => l.imagePath != null); // Oldest Log With Image.
    if (oldestLogWithImage.imagePath != null) {
      await _imageStorage.deleteImage(oldestLogWithImage.imagePath!);
    }
    
    // Update The Oldest Log.
    final updatedOldestLog = oldestLogWithImage.copyWith(
      imagePath: null,
      imageBytes: null,
    );
    
    // Update The State.
    state = [
      newLog,
      ...state.map((l) => l.id == oldestLogWithImage.id ? updatedOldestLog : l),
    ];
  }

  // Cleanup Images.
  Future<void> _cleanupImages() async {
    final activePaths = state
        .where((log) => log.imagePath != null)
        .map((log) => log.imagePath!)
        .toList();
    await _imageStorage.cleanupOldImages(activePaths);
    
    debugPrint('Saving ${state.length} logs to storage');
    debugPrint('Logs with images: ${state.where((l) => l.imagePath != null).length}');
  }

  // Get Log With Image.
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

  // Acknowledge Log.
  void acknowledgeLog(String logId) {
    state = [
      for (final log in state)
        if (log.id == logId)
          log.copyWith(isAcknowledged: true)
        else
          log,
    ];
  }

  void clearLogs() async {
    // Delete All Image Files Before Clearing Logs.
    for (final log in state) {
      if (log.imagePath != null) {
        await _imageStorage.deleteImage(log.imagePath!);
      }
    }
    state = [];
  }
}