import 'dart:async';
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
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Timer? _pollTimer;
  String? _lastImageUrl;
  bool _personDetected = false;
  DateTime? _lastDetectionTime;
  bool _isInCooldown = false;
  static const Duration cooldownDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    // Refresh devices when screen loads
    Future.microtask(() =>
        Provider.of<SecurityProvider>(context, listen: false).refreshDevices());
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkPersonStatus());
  }

  bool _canShowNewDetection() {
    if (_lastDetectionTime == null) return true;
    
    final timeSinceLastDetection = DateTime.now().difference(_lastDetectionTime!);
    return timeSinceLastDetection >= cooldownDuration;
  }

  Widget _buildImageWidget(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: frame != null
              ? child
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error');
        debugPrint('Stack trace: $stackTrace');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load image\n${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkPersonStatus() async {
    // Skip check if in cooldown period
    if (_isInCooldown) return;

    try {
      debugPrint('Checking person status...');
      final response = await http.get(
        Uri.parse(DeviceConfig.getPersonDetectionStatusUrl()),
      ).timeout(const Duration(seconds: 3));

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool newDetection = data['personDetected'] ?? false;
        final bool imageAvailable = data['imageAvailable'] ?? false;
        
        debugPrint('Person detected: $newDetection, Image available: $imageAvailable');
        
        if (newDetection && _canShowNewDetection()) {
          String? fullImageUrl;
          
          if (imageAvailable) {
            // Construct the image URL with a timestamp to prevent caching
            fullImageUrl = 'http://${DeviceConfig.gadgetServerIP}/latest_image?t=${DateTime.now().millisecondsSinceEpoch}';
            debugPrint('Full image URL: $fullImageUrl');
            
            // Pre-fetch the image to verify it's valid
            try {
              final imageResponse = await http.get(Uri.parse(fullImageUrl))
                  .timeout(const Duration(seconds: 5));
              
              if (imageResponse.statusCode != 200) {
                debugPrint('Failed to fetch image: ${imageResponse.statusCode}');
                fullImageUrl = null;
              } else {
                debugPrint('Successfully pre-fetched image: ${imageResponse.contentLength} bytes');
                debugPrint('Content-Type: ${imageResponse.headers['content-type']}');
              }
            } catch (e) {
              debugPrint('Error pre-fetching image: $e');
              fullImageUrl = null;
            }
          }
          
          if (mounted) {
            setState(() {
              _personDetected = true;
              _lastDetectionTime = DateTime.now();
              _isInCooldown = true;
              _lastImageUrl = fullImageUrl;
            });
            
            _showPersonDetectedDialog(fullImageUrl);
          }
          
          // Start cooldown timer
          Timer(cooldownDuration, () {
            if (mounted) {
              setState(() {
                _isInCooldown = false;
                _personDetected = false;
              });
            }
          });
        }
      }
    } catch (e) {
      if (!_isInCooldown) {
        debugPrint('Error checking person status: $e');
      }
    }
  }

  void _showPersonDetectedDialog(String? imageUrl) {
    if (!mounted) return;
    
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Person Detected!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A person has been detected by the camera.'),
            const SizedBox(height: 16),
            if (imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(imageUrl),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Next check in ${cooldownDuration.inSeconds} seconds',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (imageUrl != null)
            TextButton(
              onPressed: () => _showFullScreenImage(imageUrl),
              child: const Text('View Full Image'),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Captured Image'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading full screen image: $error');
                  return const Center(
                    child: Text('Failed to load image'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.pineGreen, size: 32),
            const SizedBox(width: 12),
            const Text('Security Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.pineGreen),
            onPressed: () {
              // TODO: Implement add device dialog
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppTheme.pineGreen),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<SecurityProvider>(context, listen: false)
              .refreshDevices();
        },
        color: AppTheme.pineGreen,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          slivers: [
            // Person Detection Status
            if (_personDetected)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Person Detected!',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          if (_isInCooldown)
                            Text(
                              'Cooldown: ${cooldownDuration.inSeconds}s',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Latest Image Display
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Camera Feed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepForestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.pineGreen.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _lastImageUrl != null
                            ? Image.network(
                                _lastImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      'No image available',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: AppTheme.pineGreen,
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  'Waiting for camera feed...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Original Status Header
            const SliverToBoxAdapter(
              child: StatusHeader(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Devices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepForestGreen,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to devices screen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.pineGreen,
                      ),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: DeviceGrid(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: AlertList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.pineGreen.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard,
              color: _selectedIndex == 0
                  ? AppTheme.pineGreen
                  : AppTheme.deepForestGreen.withOpacity(0.7),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.videocam,
              color: _selectedIndex == 1
                  ? AppTheme.pineGreen
                  : AppTheme.deepForestGreen.withOpacity(0.7),
            ),
            label: 'Cameras',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.notifications,
              color: _selectedIndex == 2
                  ? AppTheme.pineGreen
                  : AppTheme.deepForestGreen.withOpacity(0.7),
            ),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.pineGreen,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}