import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/security_state.dart';

class CameraImageService {
  Future<(Uint8List?, String?, String?)> fetchLatestImage(SecurityState status) async {
    if (status.cameras.isEmpty) {
      debugPrint('❌ No cameras available to fetch image from');
      return (null, null, null);
    }

    final camera = status.cameras.first;
    final url = camera['url'] as String?;
    final name = camera['name'] as String?;

    if (url == null) {
      debugPrint('❌ Camera URL is null');
      return (null, url, name);
    }

    debugPrint('📸 Attempting to fetch image from $url');
    
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Image fetch timed out after 3 seconds');
              throw TimeoutException('Image fetch timed out');
            },
          );

      if (response.statusCode == 200) {
        debugPrint('✅ Image fetched successfully');
        return (response.bodyBytes, url, name);
      } else {
        debugPrint('❌ Failed to fetch image: ${response.statusCode}');
        return (null, url, name);
      }
    } on TimeoutException catch (_) {
      // Already logged in timeout callback
      return (null, url, name);
    } catch (e) {
      debugPrint('❌ Error fetching image: $e');
      return (null, url, name);
    }
  }
} 