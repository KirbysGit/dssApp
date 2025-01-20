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
  final String gadgetIp = '172.20.10.8';
  Uint8List? _capturedImage;
  final _cameraService = CameraService();
  bool _isLoading = false;

  Future<void> _captureImage() async {
    setState(() => _isLoading = true);
    try {
      final image = await _cameraService.captureImage();
      if (mounted && image != null) {
        setState(() => _capturedImage = image);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isLoading 
                ? const CircularProgressIndicator()
                : _capturedImage != null
                  ? Image.memory(
                      _capturedImage!,
                      fit: BoxFit.contain,
                    )
                  : const Text('No image captured yet'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _captureImage,
              icon: const Icon(Icons.camera),
              label: const Text('Capture Photo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 