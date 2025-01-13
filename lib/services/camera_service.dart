import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'esp32_service.dart';

class CameraService {
  final ESP32Service _esp32Service;

  CameraService(this._esp32Service);

  Future<Uint8List?> getImageFromCamera(String nodeId) async {
    try {
      return await _esp32Service.getNodeImage(nodeId);
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }

  Stream<List<CameraNode>> get connectedNodes => _esp32Service.nodesStream;

  Future<void> refreshNodes() async {
    await _esp32Service.getConnectedNodes();
  }
} 