import 'package:flutter/material.dart';
import '../widgets/camera_feed.dart';
import '../widgets/security_card.dart';
import '../services/camera_service.dart';
import 'dart:async';
import 'dart:typed_data';

class PhotosPage extends StatefulWidget {
  const PhotosPage({Key? key}) : super(key: key);

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  final CameraService _cameraService = CameraService(baseUrl: 'http://172.20.10.8');
  Uint8List? _latestImage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startImageRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startImageRefresh() {
    // Refresh image every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshImage();
    });
  }

  Future<void> _refreshImage() async {
    final image = await _cameraService.getLatestImage('CAM1');
    if (image != null) {
      setState(() {
        _latestImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Feed'),
      ),
      body: Center(
        child: _latestImage != null
            ? Image.memory(
                _latestImage!,
                fit: BoxFit.contain,
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
} 