import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class CameraView extends StatefulWidget {
  final String ipAddress;
  final bool autoRefresh;
  final Duration refreshInterval;

  const CameraView({
    super.key, 
    required this.ipAddress,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(seconds: 2),
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  Timer? _refreshTimer;
  bool _isLoading = false;
  String? _errorMessage;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _updateImageUrl();
    
    if (widget.autoRefresh) {
      _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
        _updateImageUrl();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getImageUrl() {
    // Ensure the IP address is properly formatted
    final cleanIp = widget.ipAddress.replaceAll('http://', '').replaceAll('/', '');
    return 'http://$cleanIp/cam-hi.jpg';
  }

  Future<void> _updateImageUrl() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _imageUrl = _getImageUrl();
    });

    try {
      final response = await http.get(Uri.parse(_imageUrl))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load image';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image container with fixed aspect ratio
        AspectRatio(
          aspectRatio: 4 / 3, // Standard ESP32-CAM aspect ratio
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateImageUrl,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      _imageUrl,
                      fit: BoxFit.cover,
                      gaplessPlayback: true, // Prevents flickering between reloads
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white70,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.red[300],
                            size: 48,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        // Refresh button overlay
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _updateImageUrl,
              tooltip: 'Refresh image',
            ),
          ),
        ),
      ],
    );
  }
}