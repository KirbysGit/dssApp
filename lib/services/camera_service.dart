import 'package:http/http.dart' as http;
import 'dart:typed_data';

class CameraService {
  Future<Uint8List?> getImageFromCamera(String ipAddress) async {
    try {
      const hardcodedUrl = 'http://172.20.10.7/cam-hi.jpg';  // Hardcoded for testing
      print('Attempting to fetch image from: $hardcodedUrl');  // Debug print

      final response = await http.get(
        Uri.parse(hardcodedUrl),
        headers: {
          'Accept': 'image/jpeg',
          'Connection': 'keep-alive',
        },
      );

      print('Response status code: ${response.statusCode}');  // Debug print
      if (response.statusCode == 200) {
        print('Image size: ${response.bodyBytes.length} bytes');  // Debug print
        return response.bodyBytes;
      } else {
        print('Failed to load image: ${response.statusCode}');
        print('Response body: ${response.body}');  // Debug print
        return null;
      }
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }
}