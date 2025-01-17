import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CameraService {
  final String baseUrl;

  CameraService({required this.baseUrl}); // e.g., "http://172.20.10.8"

  Future<Uint8List?> getLatestImage(String cameraId) async {
    try {
      final url = '$baseUrl/latest-image?camera_id=$cameraId';
      print('Requesting image from: $url'); // Debug URL

      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}'); // Debug response

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to get image: ${response.statusCode}');
        return null;
      }
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
}