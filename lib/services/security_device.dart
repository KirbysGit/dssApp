import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/security_device.dart';

class SecurityService {
  final String baseUrl;
  
  SecurityService({required this.baseUrl});
  
  Future<bool> checkDeviceStatus(SecurityDevice device) async {
    try {
      final response = await http.get(
        Uri.parse('http://${device.ipAddress}/status'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<String?> captureImage(SecurityDevice device) async {
    try {
      final response = await http.get(
        Uri.parse('http://${device.ipAddress}/cam-hi.jpg'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> toggleAlarm(SecurityDevice device, bool enable) async {
    try {
      final response = await http.post(
        Uri.parse('http://${device.ipAddress}/alarm'),
        body: jsonEncode({'enabled': enable}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}