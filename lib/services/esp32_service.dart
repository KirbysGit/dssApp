import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/camera_node.dart';
import 'dart:typed_data';

class ESP32Service {
  final String baseUrl;
  final Map<String, StreamController<Uint8List>> _imageStreams = {};

  ESP32Service(this.baseUrl);

  Stream<Uint8List> getImageStream(String cameraId) {
    if (!_imageStreams.containsKey(cameraId)) {
      _imageStreams[cameraId] = StreamController<Uint8List>.broadcast();
      _startPolling(cameraId);
    }
    return _imageStreams[cameraId]!.stream;
  }

  void _startPolling(String cameraId) async {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/latest-image?camera_id=$cameraId'),
          headers: {'Accept': 'image/jpeg'},
        );

        if (response.statusCode == 200) {
          _imageStreams[cameraId]?.add(response.bodyBytes);
        }
      } catch (e) {
        print('Error polling image: $e');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void dispose() {
    for (var controller in _imageStreams.values) {
      controller.close();
    }
  }
} 