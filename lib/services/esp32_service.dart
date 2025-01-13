import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/camera_node.dart';
import 'dart:typed_data';

class ESP32Service {
  final String gadgetIP; // ESP32-S3 IP address
  final StreamController<List<CameraNode>> _nodesController = 
      StreamController<List<CameraNode>>.broadcast();

  ESP32Service(this.gadgetIP);

  Stream<List<CameraNode>> get nodesStream => _nodesController.stream;

  // Get list of connected camera nodes from ESP32-S3
  Future<List<CameraNode>> getConnectedNodes() async {
    try {
      final response = await http.get(
        Uri.parse('http://$gadgetIP/nodes'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> nodesJson = json.decode(response.body);
        final nodes = nodesJson
            .map((node) => CameraNode.fromJson(node))
            .toList();
        _nodesController.add(nodes);
        return nodes;
      } else {
        print('Failed to get nodes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting nodes: $e');
      return [];
    }
  }

  // Get latest image from a specific node
  Future<Uint8List?> getNodeImage(String nodeId) async {
    try {
      final response = await http.get(
        Uri.parse('http://$gadgetIP/node/$nodeId/image'),
        headers: {'Accept': 'image/jpeg'},
      );

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

  // Listen for alerts from ESP32-S3
  Stream<Map<String, dynamic>> listenForAlerts() async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('http://$gadgetIP/alerts'),
          headers: {'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          yield json.decode(response.body);
        }
      } catch (e) {
        print('Error listening for alerts: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void dispose() {
    _nodesController.close();
  }
} 