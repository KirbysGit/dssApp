import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraView extends StatefulWidget {
  final String ipAddress;

  const CameraView({super.key, required this.ipAddress});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  String _imageUrl = '';
  Timer? _refreshTimer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateImageUrl();
    // Refresh image every 2 seconds instead of 1 to reduce load
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateImageUrl();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateImageUrl() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _imageUrl = _getImageUrl();
    });

    try {
      final response = await http.get(Uri.parse(_imageUrl));
      print('Response status code: ${response.statusCode}');
      print('Response content-type: ${response.headers['content-type']}');
      print('Response body length: ${response.bodyBytes.length}');

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Received empty image data');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching image: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getImageUrl() {
    if (kIsWeb) {
      // Use a proxy URL for web development
      return 'http://localhost:8080/proxy?url=http://${widget.ipAddress}/cam-hi.jpg&t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'http://${widget.ipAddress}/cam-hi.jpg?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Image
                Image.network(
                  _imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      print('Image loaded successfully');
                      return child;
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading: ${((loadingProgress.cumulativeBytesLoaded / 
                              (loadingProgress.expectedTotalBytes ?? 1)) * 100).toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error displaying image: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${_errorMessage ?? error.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateImageUrl,
                    child: const Text('Refresh'),
                  ),
                  const SizedBox(width: 16),
                  Text('IP: ${widget.ipAddress}'),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}