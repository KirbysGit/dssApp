import '../models/detection_log.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_provider.dart';
import 'dart:typed_data';
import 'camera_service.dart';
import '../screens/alert_screen.dart';
import 'package:http/http.dart' as http;
import 'image_storage_service.dart';
import 'package:uuid/uuid.dart';

// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationData {
  final String title;
  final String body;
  final DateTime timestamp;
  final String? cameraName;
  final Uint8List? image;
  final String? debugInfo;

  NotificationData({
    required this.title,
    required this.body,
    required this.timestamp,
    this.cameraName,
    this.image,
    this.debugInfo,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'cameraName': cameraName,
    'debugInfo': debugInfo,
  };

  factory NotificationData.fromJson(Map<String, dynamic> json) => NotificationData(
    title: json['title'] as String,
    body: json['body'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    cameraName: json['cameraName'] as String?,
    debugInfo: json['debugInfo'] as String?,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final CameraService _cameraService = CameraService();
  final ImageStorageService _imageStorage = ImageStorageService();
  late ProviderContainer _container;
  Timer? _pollTimer;
  final _notificationStreamController = StreamController<NotificationData>.broadcast();
  
  Stream<NotificationData> get notificationStream => _notificationStreamController.stream;
  
  // Queue to manage notifications
  final List<NotificationData> _notificationQueue = [];
  static const int maxQueueSize = 5;  // Maximum number of notifications to keep

  // Cache the latest notification data for handling taps
  NotificationData? _latestNotification;
  Uint8List? _latestImage;

  final _uuid = Uuid();

  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    
    // Initialize notification settings
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    // Create the notification channel with high importance
    const androidChannel = AndroidNotificationChannel(
      'person_detection_channel',
      'Person Detection',
      description: 'Notifications for person detection',
      importance: Importance.max,
      enableVibration: true,
      showBadge: true,
      playSound: true,
      enableLights: true,
    );

    // Initialize notifications and create channel
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details);
      },
    );

    // Create the Android-specific notification channel
    final platform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(androidChannel);
  }

  void _handleNotificationTap(NotificationResponse details) {
    debugPrint('Notification tapped: ${details.payload}');
    
    if (details.payload != null) {
      try {
        final data = NotificationData.fromJson(jsonDecode(details.payload!));
        
        // Navigate to AlertScreen
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => AlertScreen(
            image: _latestImage,
            cameraName: data.cameraName ?? 'Unknown Camera',
            timestamp: data.timestamp,
          ),
        ));
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    }
  }

  // Test method to verify notifications
  Future<void> sendTestNotification() async {
    debugPrint('Sending test notification...');
    await _showNotification(null, isTest: true);
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
      final gadgetIp = _container.read(gadgetIpProvider);
      /// debugPrint('Checking for person detection...');
      final response = await _cameraService.checkPersonDetection(gadgetIp);
      // debugPrint('Person detection response: $response');
      
      if (response != null) {
        final bool isPersonDetected = response['personDetected'] ?? false;
        /// debugPrint('Person detected status: $isPersonDetected');
        
        if (isPersonDetected) {
          debugPrint('Person detected - fetching latest image...');
          
          // Get the camera URL from the response
          final String? cameraUrl = response['cameraUrl'] as String?;
          final String? cameraName = response['cameraName'] as String?;
          
          // Get the camera URL from the cameras array if not provided directly
          final String imageUrl = cameraUrl ?? 
            (response['cameras'] as List?)?.firstWhere(
              (camera) => camera['url'] != null,
              orElse: () => {'url': 'http://$gadgetIp/capture'}
            )['url'] as String? ?? 
            'http://$gadgetIp/capture';

          final String logId = DateTime.now().millisecondsSinceEpoch.toString();
          
          // Create initial detection log
          final detectionLog = DetectionLog(
            id: logId,
            timestamp: DateTime.now(),
            cameraName: cameraName ?? 'Unknown Camera',
            cameraUrl: cameraUrl ?? '',
            imageUrl: imageUrl,
            isAcknowledged: false,
            wasAlarmTriggered: true,
          );
          
          // Save initial log
          _container.read(detectionLogsProvider.notifier).addDetectionLog(detectionLog);
          
          // Update security status
          _container.read(securityStatusProvider.notifier).updateWithDetection(
            isPersonDetected: true,
            lastDetectionTime: DateTime.now(),
            detectedCamera: {
              'name': cameraName,
              'url': cameraUrl,
            },
          );

          // Try to fetch image
          final image = await _fetchImageWithRetry(imageUrl);
          String? imagePath;
          
          if (image != null) {
            debugPrint('Image fetched successfully, saving to storage...');
            try {
              // Save image to local storage
              imagePath = await _imageStorage.saveImage(image, logId);
              debugPrint('Image saved to: $imagePath');
              
              // Update log with image path and temporary bytes
              _container.read(detectionLogsProvider.notifier).addDetectionLog(
                detectionLog.copyWith(
                  imagePath: imagePath,
                  imageBytes: image,
                )
              );
            } catch (e) {
              debugPrint('Error saving image: $e');
            }
          } else {
            debugPrint('Image fetch failed');
          }
          
          // Show notification
          await _showNotification(
            image,
            cameraName: cameraName,
            cameraUrl: cameraUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking person detection: $e');
    }
  }

  Future<void> _showNotification(
    Uint8List? imageBytes, {
    bool isTest = false,
    String? cameraName,
    String? cameraUrl,
  }) async {
    debugPrint('Showing notification with image: ${imageBytes != null ? '${imageBytes.length} bytes' : 'null'}');
    
    final gadgetIp = _container.read(gadgetIpProvider);
    final notification = NotificationData(
      title: isTest ? 'Test Notification' : 'Person Detected!',
      body: isTest 
          ? 'This is a test notification to verify the system is working.'
          : 'A person has been detected by ${cameraName ?? 'your security system'}.',
      timestamp: DateTime.now(),
      cameraName: cameraName ?? 'Camera Node 1',
      image: imageBytes,
      debugInfo: 'Gadget IP: $gadgetIp${cameraUrl != null ? '\nCamera URL: $cameraUrl' : ''}',
    );

    // Cache the latest notification data and image
    _latestNotification = notification;
    _latestImage = imageBytes;

    // Add to queue and maintain max size
    _addToNotificationQueue(notification);

    // Configure the notification style
    final BigTextStyleInformation styleInfo = BigTextStyleInformation(
      notification.body,
      htmlFormatBigText: true,
      contentTitle: notification.title,
      htmlFormatContentTitle: true,
      summaryText: 'SecureScape Alert',
      htmlFormatSummaryText: true,
    );

    // Create the notification details
    final androidDetails = AndroidNotificationDetails(
      'person_detection_channel',
      'Person Detection',
      channelDescription: 'Notifications for person detection',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: styleInfo,
      ticker: 'Person detected',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: [
        const AndroidNotificationAction('view', 'View Alert'),
        const AndroidNotificationAction('dismiss', 'Dismiss'),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(notification.toJson()),
      );
      debugPrint('Local notification shown successfully');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Get all notifications
  List<NotificationData> getNotifications() => List.unmodifiable(_notificationQueue);

  // Clear all notifications
  void clearNotifications() {
    _notificationQueue.clear();
    _notificationStreamController.add(NotificationData(
      title: '',
      body: '',
      timestamp: DateTime.now(),
    )); // Trigger UI update
  }

  // Remove a specific notification
  void removeNotification(int id) {
    _notificationQueue.removeWhere((notification) => notification.timestamp.millisecondsSinceEpoch == id);
    if (_notificationQueue.isNotEmpty) {
      _notificationStreamController.add(_notificationQueue.first);
    }
  }

  void dispose() {
    stopPolling();
    _notificationStreamController.close();
  }

  void _addToNotificationQueue(NotificationData notification) {
    _notificationQueue.insert(0, notification);
    if (_notificationQueue.length > maxQueueSize) {
      _notificationQueue.removeLast();
    }
    _notificationStreamController.add(notification);
  }

  Future<Uint8List?> _fetchImageWithRetry(String url, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Image fetch timed out');
          },
        );

        if (response.statusCode == 200 && 
            response.headers['content-type']?.contains('image/') == true) {
          return response.bodyBytes;
        }
        throw Exception('Invalid image response');
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          print('All retry attempts failed for image fetch: $e');
          return null;
        }
        print('Retry attempt $attempt after error: $e');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  Future<void> handlePersonDetection(String cameraName, String cameraUrl, DetectionLogsNotifier logsNotifier) async {
    final logId = _uuid.v4();
    print('Creating detection log with ID: $logId');

    // Create initial log without image
    final detectionLog = DetectionLog(
      id: logId,
      timestamp: DateTime.now(),
      cameraName: cameraName,
      cameraUrl: cameraUrl,
      imageUrl: null,
      imagePath: null,
    );

    // Start image fetch process
    try {
      final imageBytes = await _fetchImageWithRetry(cameraUrl);
      String? imagePath;
      
      if (imageBytes != null) {
        // Save image to storage and get path
        imagePath = await _imageStorage.saveImage(imageBytes, logId);
        print('Image saved successfully at path: $imagePath');
      }

      // Create updated log with image information
      final updatedLog = detectionLog.copyWith(
        imagePath: imagePath,
        imageBytes: imageBytes,
      );

      // Add log to provider
      logsNotifier.addDetectionLog(updatedLog);

      // Show notification
      await _showNotification(
        imageBytes,
        cameraName: cameraName,
        cameraUrl: cameraUrl,
      );
    } catch (e) {
      print('Error during image fetch and notification: $e');
      // Still show notification even if image fetch fails
      logsNotifier.addDetectionLog(detectionLog);
      await _showNotification(
        null,
        cameraName: cameraName,
        cameraUrl: cameraUrl,
      );
    }
  }
} 