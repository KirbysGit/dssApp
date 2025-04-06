import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/device_config.dart';

class CameraService {
  Future<Map<String, dynamic>?> checkPersonDetection(String gadgetIp) async {
    try {
      final response = await http.get(
        Uri.parse('http://$gadgetIp/person_status'),
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

  Future<Uint8List?> getLatestImage(String gadgetIp) async {
    try {
      final response = await http.get(Uri.parse('http://$gadgetIp/latest_image'));
      print('Requesting from: http://$gadgetIp/latest_image'); // This will help us debug
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error getting image: $e');
      return null;
    }
  }

  Future<Uint8List?> getImageFromCamera(String gadgetIp, String cameraIp) async {
    try {
      final response = await http.get(Uri.parse('http://$gadgetIp/camera/$cameraIp/image'));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error fetching camera image: $e');
      return null;
    }
  }

  Future<Uint8List?> captureImage({required String gadgetIp}) async {
    try {
      final response = await http.get(Uri.parse('http://$gadgetIp/capture'));
      print('Capturing image from: http://$gadgetIp/capture');
      
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