import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'camera_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final CameraService _cameraService = CameraService();
  Timer? _pollTimer;
  final _notificationStreamController = StreamController<NotificationData>.broadcast();
  
  Stream<NotificationData> get notificationStream => _notificationStreamController.stream;
  
  // Queue to manage notifications
  final List<NotificationData> _notificationQueue = [];
  static const int maxQueueSize = 5;  // Maximum number of notifications to keep

  Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
  }

  void startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkForPersonDetection());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkForPersonDetection() async {
    try {
      print('Checking for person detection...');  // Debug output
      final response = await _cameraService.checkPersonDetection();
      print('Person detection response: $response');  // Debug output
      
      if (response != null) {
        // The gadget returns personDetected as a boolean
        final bool isPersonDetected = response['personDetected'] ?? false;
        print('Person detected status: $isPersonDetected');  // Debug output
        
        if (isPersonDetected) {
          print('Fetching latest image...');  // Debug output
          final image = await _cameraService.getLatestImage();
          print('Image fetched: ${image != null ? '${image.length} bytes' : 'null'}');  // Debug output
          await _showNotification(image);
        }
      }
    } catch (e) {
      print('Error checking person detection: $e');
    }
  }

  Future<void> _showNotification(Uint8List? imageBytes) async {
    print('Showing notification with image: ${imageBytes != null ? '${imageBytes.length} bytes' : 'null'}');  // Debug output
    
    // Create notification data
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Person Detected!',
      body: 'A person has been detected by your security system.',
      timestamp: DateTime.now(),
      image: imageBytes,
    );

    // Add to queue and maintain max size
    _notificationQueue.insert(0, notification);
    if (_notificationQueue.length > maxQueueSize) {
      _notificationQueue.removeLast();
    }

    print('Added notification to queue. Queue size: ${_notificationQueue.length}');  // Debug output

    // Notify listeners
    _notificationStreamController.add(notification);
    print('Notified stream listeners');  // Debug output

    // Show local notification
    const androidDetails = AndroidNotificationDetails(
      'person_detection_channel',
      'Person Detection',
      channelDescription: 'Notifications for person detection',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        notification.id,
        notification.title,
        notification.body,
        notificationDetails,
      );
      print('Local notification shown successfully');  // Debug output
    } catch (e) {
      print('Error showing local notification: $e');  // Debug output
    }
  }

  // Get all notifications
  List<NotificationData> getNotifications() => List.unmodifiable(_notificationQueue);

  // Clear all notifications
  void clearNotifications() {
    _notificationQueue.clear();
    _notificationStreamController.add(NotificationData(
      id: -1,
      title: '',
      body: '',
      timestamp: DateTime.now(),
    )); // Trigger UI update
  }

  // Remove a specific notification
  void removeNotification(int id) {
    _notificationQueue.removeWhere((notification) => notification.id == id);
    if (_notificationQueue.isNotEmpty) {
      _notificationStreamController.add(_notificationQueue.first);
    }
  }

  void dispose() {
    stopPolling();
    _notificationStreamController.close();
  }
}

class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Uint8List? image;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.image,
  });
} 