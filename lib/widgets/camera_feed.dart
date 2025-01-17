import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import '../services/camera_service.dart';

class CameraFeed extends StatefulWidget {
  final String ipAddress;
  final Duration refreshRate;

  const CameraFeed({
    Key? key,
    required this.ipAddress,
    this.refreshRate = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  final CameraService _cameraService = CameraService(baseUrl: 'http://localhost:8080');
  Timer? _timer;
  Uint8List? _currentImage;

  @override
  void initState() {
    super.initState();
    _startImageFetch();
  }

  void _startImageFetch() {
    _timer = Timer.periodic(widget.refreshRate, (timer) async {
      final image = await _cameraService.getImageFromCamera(widget.ipAddress);
      if (image != null && mounted) {
        setState(() {
          _currentImage = image;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Image.memory(
      _currentImage!,
      fit: BoxFit.contain,
      gaplessPlayback: true, // Prevents flickering
    );
  }
} 