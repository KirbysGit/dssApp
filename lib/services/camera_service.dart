import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/device_config.dart';

class CameraService {
  static const String baseUrl = 'http://172.20.10.8';  // Correct gadget IP

  Future<Map<String, dynamic>?> checkPersonDetection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/person_status'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('Person detection response: ${response.body}');  // Debug output
        return json.decode(response.body);
      }
      print('Person detection status code: ${response.statusCode}');  // Debug output
      return null;
    } catch (e) {
      print('Error checking person detection: $e');
      return null;
    }
  }

  Future<Uint8List?> getLatestImage() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/latest_image'));
      print('Requesting from: $baseUrl/latest_image'); // This will help us debug
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error getting image: $e');
      return null;
    }
  }

  Future<Uint8List?> getImageFromCamera(String ipAddress) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/camera/$ipAddress/image'));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error fetching camera image: $e');
      return null;
    }
  }

  Future<Uint8List?> captureImage() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/capture'));
      print('Capturing image from: $baseUrl/capture');
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }
}