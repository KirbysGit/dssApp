import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../widgets/device_grid.dart';
import '../widgets/status_header.dart';
import '../widgets/alert_list.dart';
import '../screens/camera_screen.dart';
import '../theme/app_theme.dart';
import '../config/device_config.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _personDetected = false;
  Timer? _statusCheckTimer;
  Image? _latestImage;
  DateTime? _lastDetectionTime;
  bool _isLoading = false;
  
  // ESP32 Gadget IP address
  final String gadgetIp = '172.20.10.8';

  @override
  void initState() {
    super.initState();
    _startStatusChecking();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusChecking() {
    // Check every 2 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPersonStatus();
    });
  }

  Future<void> _checkPersonStatus() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://$gadgetIp/person_status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool newDetection = data['personDetected'] ?? false;
        
        if (newDetection && !_personDetected) {
          // New person detected, fetch the image
          _lastDetectionTime = DateTime.now();
          await _fetchLatestImage();
          if (mounted) {
            _showDetectionAlert();
          }
        }
        
        if (mounted) {
          setState(() {
            _personDetected = newDetection;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking person status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLatestImage() async {
    try {
      final response = await http.get(
        Uri.parse('http://$gadgetIp/latest_image'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _latestImage = Image.memory(
            response.bodyBytes,
            fit: BoxFit.contain,
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching image: $e');
    }
  }

  void _showDetectionAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Person Detected!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Time: ${_lastDetectionTime?.toString() ?? "Unknown"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_latestImage != null)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _latestImage!,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add action for emergency response
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Emergency Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkPersonStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              _personDetected ? Icons.warning : Icons.check_circle,
                              color: _personDetected ? Colors.red : Colors.green,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _personDetected ? 'Person Detected!' : 'All Clear',
                                    style: TextStyle(
                                      color: _personDetected ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (_lastDetectionTime != null)
                                    Text(
                                      'Last Detection: ${_lastDetectionTime.toString()}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_latestImage != null) ...[
                  Text(
                    'Latest Detection Image',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _latestImage!,
                          ),
                          if (_lastDetectionTime != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Captured: ${_lastDetectionTime.toString()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkPersonStatus,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}