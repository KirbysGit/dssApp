// lib/services/security_device.dart

// Description :
// This file contains the SecurityService class which is responsible for :
// - Checking the device status.
// - Capturing the image.
// - Toggling the alarm.
  
// Importing Dart Async Package.
import 'dart:async';

// Importing HTTP Package.
import 'dart:convert';
import 'package:http/http.dart' as http;

// Importing Security Device Model.
import '../models/security_device.dart';

// Security Service Class.
class SecurityService {
  // Base URL.
  final String baseUrl;
  
  // Constructor.
  SecurityService({required this.baseUrl});
  
  // Check Device Status.
  Future<bool> checkDeviceStatus(SecurityDevice device) async {
    try {
      // Get The Device Status.
      final response = await http.get(
        Uri.parse('http://${device.ipAddress}/status'),
      ).timeout(const Duration(seconds: 5));

      // If The Status Code Is 200.
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Capture Image.
  Future<String?> captureImage(SecurityDevice device) async {
    try {
      // Get The Image.
      final response = await http.get(
        Uri.parse('http://${device.ipAddress}/cam-hi.jpg'),
      ).timeout(const Duration(seconds: 10));
      
      // If The Status Code Is 200.
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Toggle Alarm.
  Future<bool> toggleAlarm(SecurityDevice device, bool enable) async {
    try {
      // Toggle The Alarm.
      final response = await http.post(
        Uri.parse('http://${device.ipAddress}/alarm'),
        body: jsonEncode({'enabled': enable}),
      );

      // If The Status Code Is 200.
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}