import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CameraService {
  static const String baseUrl = 'http://172.20.10.8'; // Make sure this is correct

  Future<Uint8List?> getLatestImage() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/latest-image'));
      print('Requesting from: $baseUrl/latest-image'); // This will help us debug
      
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