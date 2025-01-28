import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/device_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _pollTimer;
  
  Future<void> initialize() async {
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(initializationSettings);
  }

  void startPolling() {
    // Poll the gadget server every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkForPersonDetection());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkForPersonDetection() async {
    try {
      final response = await http.get(
        Uri.parse('http://${DeviceConfig.gadgetServerIP}/person-status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (response.body.contains('true')) {
          _showNotification();
        }
      }
    } catch (e) {
      print('Error checking person detection: $e');
    }
  }

  Future<void> _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'person_detection_channel',
      'Person Detection',
      channelDescription: 'Notifications for person detection',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Person Detected!',
      'A person has been detected by your security system.',
      notificationDetails,
    );
  }
} 