import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/device_config.dart';

class PersonDetectionService {
  // Singleton pattern
  static final PersonDetectionService _instance = PersonDetectionService._internal();
  factory PersonDetectionService() => _instance;
  PersonDetectionService._internal();

  // Stream controller for person detection status
  final _personDetectionController = StreamController<bool>.broadcast();
  Stream<bool> get personDetectionStream => _personDetectionController.stream;

  Timer? _pollingTimer;
  bool _isPolling = false;

  // Start polling the person detection status
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    
    // Poll every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      checkPersonDetectionStatus();
    });
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
  }

  // Check person detection status
  Future<void> checkPersonDetectionStatus() async {
    try {
      final response = await http.get(
        Uri.parse(DeviceConfig.getPersonDetectionStatusUrl()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool isPersonDetected = data['personDetected'] ?? false;
        _personDetectionController.add(isPersonDetected);
      }
    } catch (e) {
      print('Error checking person detection status: $e');
      _personDetectionController.add(false);
    }
  }

  // Manually trigger person detection (for testing)
  Future<bool> triggerPersonDetection() async {
    try {
      final response = await http.post(
        Uri.parse('${DeviceConfig.getGadgetServerUrl()}/person_detected'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Error triggering person detection: $e');
      return false;
    }
  }

  // Cleanup
  void dispose() {
    stopPolling();
    _personDetectionController.close();
  }
} 