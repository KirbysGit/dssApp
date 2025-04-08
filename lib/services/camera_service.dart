// lib/services/camera_service.dart

// Description :
// This file contains the CameraService class which is responsible :
// - Checking person detection.
// - Getting the latest image.
// - Getting an image from a camera.
// - Capturing an image.

// Importing Dart Typed Data & HTTP Packages.
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// Importing JSON Package.
import 'dart:convert';

// Camera Service Class.
class CameraService {
  // Check Person Detection.
  Future<Map<String, dynamic>?> checkPersonDetection(String gadgetIp) async {
    try {
      // Get The Person Status.
      final response = await http.get(
        Uri.parse('http://$gadgetIp/person_status'),
      ).timeout(const Duration(seconds: 5));

      // If The Status Code Is 200.
      if (response.statusCode == 200) {
        // print('Person detection response: ${response.body}');  // Debug output
        return json.decode(response.body);
      }
      // print('Person detection status code: ${response.statusCode}');  // Debug output
      return null;
    } catch (e) {
      print('Error checking person detection: $e');
      return null;
    }
  }

  // Get Latest Image.
  Future<Uint8List?> getLatestImage(String gadgetIp) async {
    try {

      // Get The Latest Image.  
      final response = await http.get(Uri.parse('http://$gadgetIp/latest_image'));
      
      // If The Status Code Is 200.
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error getting image: $e');
      return null;
    }
  }

  // Get Image From Camera.
  Future<Uint8List?> getImageFromCamera(String gadgetIp, String cameraIp) async {
    try {
      // Get The Image From The Camera.
      final response = await http.get(Uri.parse('http://$gadgetIp/camera/$cameraIp/image'));

      // If The Status Code Is 200.
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error fetching camera image: $e');
      return null;
    }
  }

  // Capture Image.
  Future<Uint8List?> captureImage({required String gadgetIp}) async {
    try {
      // Capture The Image.
      final response = await http.get(Uri.parse('http://$gadgetIp/capture'));

      // If The Status Code Is 200.
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