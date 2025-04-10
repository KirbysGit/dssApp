// lib/services/notification_service.dart

// Description :
// This file contains the NotificationService class which is responsible for :
// - Sending notifications.
// - Handling notification taps.


// Importing Required Packages.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'camera_service.dart';
import 'package:uuid/uuid.dart';
import 'image_storage_service.dart';
import '../screens/alert_screen.dart';
import '../models/detection_log.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/security_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global Navigator Key.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Notification Data Class.
class NotificationData {
  final String title;         // Title.
  final String body;          // Body.
  final DateTime timestamp;   // Timestamp.
  final String? cameraName;   // Camera Name.
  final Uint8List? image;     // Image.
  final String? debugInfo;    // Debug Info.

  // Constructor.
  NotificationData({
    required this.title,
    required this.body,
    required this.timestamp,
    this.cameraName,
    this.image,
    this.debugInfo,
  });

  // Convert To JSON.
  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'cameraName': cameraName,
    'debugInfo': debugInfo,
  };

  // Factory Constructor.
  factory NotificationData.fromJson(Map<String, dynamic> json) => NotificationData(
    title: json['title'] as String,
    body: json['body'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    cameraName: json['cameraName'] as String?,
    debugInfo: json['debugInfo'] as String?,
  );
}

// Notification Service Class.
class NotificationService {
  // Private Constructor.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Flutter Local Notifications Plugin.
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Camera Service.
  final CameraService _cameraService = CameraService();

  // Image Storage Service.
  final ImageStorageService _imageStorage = ImageStorageService();
  late ProviderContainer _container;
  Timer? _pollTimer;  

  // Notification Stream Controller.
  final _notificationStreamController = StreamController<NotificationData>.broadcast();
  
  // Notification Stream.
  Stream<NotificationData> get notificationStream => _notificationStreamController.stream;
  
  // Queue to manage notifications
  final List<NotificationData> _notificationQueue = [];
  static const int maxQueueSize = 5;  // Maximum number of notifications to keep

  // Cache Latest Notification.
  NotificationData? _latestNotification;
  Uint8List? _latestImage;

  // UUID.
  final _uuid = Uuid();

  // App In Foreground.
  bool _isAppInForeground = true;

  // Set App Lifecycle State.
  void setAppLifecycleState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  // Initialize.
  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    
    debugPrint('🔄 Initializing notification service...');
    
    // Initialize Notification Settings.
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    // Create The Notification Channel With High Importance.
    const androidChannel = AndroidNotificationChannel(
      'person_detection_channel',
      'Person Detection',
      description: 'Notifications for person detection',
      importance: Importance.max,
      enableVibration: true,
      showBadge: true,
      playSound: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    debugPrint('📱 Setting up notification channel...');

    // Initialize Notifications And Create Channel.
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details);
      },
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTap,
    );

    // Create The Android-Specific Notification Channel.
    final platform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(androidChannel);

    // Request notification permissions
    final permissionGranted = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    debugPrint('📱 Notification permission granted: $permissionGranted');
    
    if (permissionGranted != true) {
      debugPrint('⚠️ Notification permissions not granted!');
    }
  }

  // Handle Notification Tap.
  void _handleNotificationTap(NotificationResponse details) {
    debugPrint('Notification tapped: ${details.payload}');
    
    if (details.payload != null) {
      try {
        final data = NotificationData.fromJson(jsonDecode(details.payload!));
        
        // Navigate To AlertScreen.
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

  // Handle Background Notification Tap.
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse details) {
    // This method needs to be static and annotated with @pragma('vm:entry-point')
    final notification = NotificationService();
    notification._handleNotificationTap(details);
  }

  // Test Method To Verify Notifications.
  Future<void> sendTestNotification() async {
    debugPrint('Sending test notification...');
    await _showNotification(null, isTest: true);
  }

  // Start Polling.
  void startPolling() {
    debugPrint('🔄 Starting detection polling...');
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkForPersonDetection());
  }

  // Stop Polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // Check For Person Detection.
  Future<void> _checkForPersonDetection() async {
    try {

      // Get The Gadget IP.
      final gadgetIp = _container.read(gadgetIpProvider);

      // Check For Person Detection.
      final response = await _cameraService.checkPersonDetection(gadgetIp);
      
      // If The Response Is Not Null.
      if (response != null) {
        // Get The Person Detection Status.
        final bool isPersonDetected = response['personDetected'] ?? false;
        
        // If The Person Is Detected.
        if (isPersonDetected) {
          // Get The Camera URL.
          final String? cameraUrl = response['cameraUrl'] as String?;
          final String? cameraName = response['cameraName'] as String?;
          
          // Get The Camera URL.
          final String imageUrl = cameraUrl ?? 
            (response['cameras'] as List?)?.firstWhere(
              (camera) => camera['url'] != null,
              orElse: () => {'url': 'http://$gadgetIp/capture'}
            )['url'] as String? ?? 
            'http://$gadgetIp/capture';

          // Create The Log ID.
          final String logId = DateTime.now().millisecondsSinceEpoch.toString();
          
          // Create The Detection Log.
          final detectionLog = DetectionLog(
            id: logId,                                  // Log ID.
            timestamp: DateTime.now(),                  // Timestamp.
            cameraName: cameraName ?? 'Unknown Camera', // Camera Name.
            cameraUrl: cameraUrl ?? '',                 // Camera URL.
            imageUrl: imageUrl,                         // Image URL.
            isAcknowledged: false,                      // Is Acknowledged.
            wasAlarmTriggered: true,                    // Was Alarm Triggered.
          );

          // Save The Initial Log.
          _container.read(detectionLogsProvider.notifier).addDetectionLog(detectionLog);
          
          // Update Security Status.
          _container.read(securityStatusProvider.notifier).updateWithDetection(
            isPersonDetected: true,                       // Is Person Detected.
            lastDetectionTime: DateTime.now(),            // Last Detection Time.
            detectedCamera: {
              'name': cameraName,                         // Camera Name.
              'url': cameraUrl,                           // Camera URL.
            },
          );

          // Try To Fetch Image.
          final image = await _fetchImageWithRetry(imageUrl);
          String? imagePath;
          
          // If The Image Is Not Null.
          if (image != null) {
            debugPrint('Image fetched successfully, saving to storage...');
            try {
              // Save Image To Local Storage.
              imagePath = await _imageStorage.saveImage(image, logId);
              debugPrint('Image saved to: $imagePath');
              
              // Update Log With Image Path And Temporary Bytes.
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
          
          // Show Notification.
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

  // Show Notification.
  Future<void> _showNotification(
    Uint8List? imageBytes, {
    bool isTest = false,
    String? cameraName,
    String? cameraUrl,
  }) async {
    try {
      final gadgetIp = _container.read(gadgetIpProvider); 

      // Create unique notification ID
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      debugPrint('🔔 Creating notification with ID: $notificationId');

      // Create notification content
      final notification = NotificationData(
        title: isTest ? 'Test Notification' : '🚨 Person Detected!',
        body: isTest 
            ? 'This is a test notification to verify the system is working.'
            : 'A person has been detected by ${cameraName ?? 'your security system'}.',
        timestamp: DateTime.now(),
        cameraName: cameraName ?? 'Camera Node 1',
        image: imageBytes,
        debugInfo: 'Gadget IP: $gadgetIp${cameraUrl != null ? '\nCamera URL: $cameraUrl' : ''}',
      );

      // Cache notification data
      _latestNotification = notification;
      _latestImage = imageBytes;
      _addToNotificationQueue(notification);

      // Configure Android notification details
      final androidDetails = AndroidNotificationDetails(
        'person_detection_channel',
        'Person Detection',
        channelDescription: 'Notifications for person detection',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        channelShowBadge: true,
        autoCancel: true,
        ticker: 'Person detected!',
      );

      debugPrint('🔔 Showing system notification...');

      // Always show the system notification first
      await _notifications.show(
        notificationId,
        notification.title,
        notification.body,
        NotificationDetails(android: androidDetails),
        payload: jsonEncode(notification.toJson()),
      );

      debugPrint('✅ System notification shown successfully');

      // Then update the security status
      if (!isTest) {
        debugPrint('🔄 Updating security status...');
        _container.read(securityStatusProvider.notifier).updateWithDetection(
          isPersonDetected: true,
          lastDetectionTime: DateTime.now(),
          detectedCamera: {
            'name': cameraName,
            'url': cameraUrl,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
      // Even if system notification fails, try to update security status
      if (!isTest) {
        _container.read(securityStatusProvider.notifier).updateWithDetection(
          isPersonDetected: true,
          lastDetectionTime: DateTime.now(),
          detectedCamera: {
            'name': cameraName,
            'url': cameraUrl,
          },
        );
      }
    }
  }

  // Get All Notifications.
  List<NotificationData> getNotifications() => List.unmodifiable(_notificationQueue);

  // Clear All Notifications.
  void clearNotifications() {
    _notificationQueue.clear();
    _notificationStreamController.add(NotificationData(
      title: '',
      body: '',
      timestamp: DateTime.now(),
    )); // Trigger UI Update.
  }

  // Remove A Specific Notification.
  void removeNotification(int id) {
    _notificationQueue.removeWhere((notification) => notification.timestamp.millisecondsSinceEpoch == id);
    if (_notificationQueue.isNotEmpty) {
      _notificationStreamController.add(_notificationQueue.first);
    }
  }

  // Dispose.
  void dispose() {
    stopPolling();
    _notificationStreamController.close();
  }

  // Add To Notification Queue.
  void _addToNotificationQueue(NotificationData notification) {
    _notificationQueue.insert(0, notification);
    if (_notificationQueue.length > maxQueueSize) {
      _notificationQueue.removeLast();
    }
    _notificationStreamController.add(notification);
  }

  // Fetch Image With Retry.
  Future<Uint8List?> _fetchImageWithRetry(String url, {int maxRetries = 3}) async {
    // Attempt.
    int attempt = 0;

    // While Attempt Is Less Than Max Retries.
    while (attempt < maxRetries) {
      try {
        // Get The Image.
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Image fetch timed out');
          },
        );

        // If The Status Code Is 200 And The Content Type Is Image.
        if (response.statusCode == 200 && 
            response.headers['content-type']?.contains('image/') == true) {
          return response.bodyBytes;
        }
        throw Exception('Invalid image response');
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          print('All Retry Attempts Failed For Image Fetch: $e');
          return null;
        }
        print('Retry Attempt $attempt After Error: $e');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  // Handle Person Detection.
  Future<void> handlePersonDetection(String cameraName, String cameraUrl, DetectionLogsNotifier logsNotifier) async {
    final logId = _uuid.v4();
    print('Creating detection log with ID: $logId');

    // Create Initial Log Without Image.
    final detectionLog = DetectionLog(
      id: logId,
      timestamp: DateTime.now(),
      cameraName: cameraName,
      cameraUrl: cameraUrl,
      imageUrl: null,
      imagePath: null,
    );

    // Start Image Fetch Process.
    try {
      final imageBytes = await _fetchImageWithRetry(cameraUrl);
      String? imagePath;
      
      if (imageBytes != null) {
        // Save Image To Storage And Get Path.
        imagePath = await _imageStorage.saveImage(imageBytes, logId);
        print('Image saved successfully at path: $imagePath');
      }

      // Create Updated Log With Image Information.
      final updatedLog = detectionLog.copyWith(
        imagePath: imagePath,
        imageBytes: imageBytes,
      );

      // Add Log To Provider.
      logsNotifier.addDetectionLog(updatedLog);

      // Show Notification.
      await _showNotification(
        imageBytes,
        cameraName: cameraName,
        cameraUrl: cameraUrl,
      );
    } catch (e) {
      print('Error during image fetch and notification: $e');
      // Still Show Notification Even If Image Fetch Fails.
      logsNotifier.addDetectionLog(detectionLog);
      await _showNotification(
        null,
        cameraName: cameraName,
        cameraUrl: cameraUrl,
      );
    }
  }

  // Show Notification.
  Future<void> showNotification({
    required String title,
    required String body,
    String? cameraName,
    String? cameraUrl,
    String? imageUrl,
  }) async {
    // Show System Notification Regardless Of App State.
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'security_alerts',
      'Security Alerts',
      channelDescription: 'Notifications for security alerts',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Show The Notification.
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformChannelSpecifics,
    );

    // Update The Security Status Which Will Trigger In-App Alert.
    _container.read(securityStatusProvider.notifier).updateWithDetection(
      isPersonDetected: true,
      lastDetectionTime: DateTime.now(),
      detectedCamera: {
        'name': cameraName,
        'url': cameraUrl,
      },
    );
  }
} 