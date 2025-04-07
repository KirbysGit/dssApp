import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_provider.dart';
import '../models/security_state.dart';
import '../services/notification_service.dart';
import './cameras_screen.dart';
import './logs_screen.dart';
import './test_gadget_screen.dart';
import './alert_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Image? _latestImage;
  Uint8List? _latestImageBytes;
  bool _alertVisible = false;
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy, hh:mm a');
  String? _activeCameraUrl;
  String? _activeCameraName;
  bool _isFetchingImage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();

    // Start periodic image updates
    _startImageUpdates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showDetectionAlert(SecurityState status) async {
    if (_alertVisible || !mounted) return;

    _alertVisible = true;
    
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlertScreen(
          image: _latestImageBytes,
          cameraName: _activeCameraName ?? 'Unknown Camera',
          timestamp: status.lastDetectionTime ?? DateTime.now(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _alertVisible = false;
        });
      }
    });
  }

  Future<void> _fetchLatestImage(SecurityState status) async {
    if (status.cameras.isEmpty) {
      debugPrint('No cameras available');
      return;
    }

    // If we're already showing an alert, don't fetch again
    if (_alertVisible) {
      debugPrint('Alert visible, skipping fetch');
      return;
    }

    // If we're already fetching, wait for the current fetch to complete
    if (_isFetchingImage) {
      debugPrint('Already fetching image, waiting...');
      return;
    }

    debugPrint('Starting image fetch...');
    setState(() => _isFetchingImage = true);

    try {
      // Find the most recent camera
      final mostRecentCamera = status.cameras.reduce((curr, next) => 
        (curr['lastSeen'] ?? 0) > (next['lastSeen'] ?? 0) ? curr : next
      );

      final cameraUrl = mostRecentCamera['url'] as String?;
      if (cameraUrl == null) {
        debugPrint('No camera URL available');
        return;
      }

      setState(() {
        _activeCameraUrl = cameraUrl;
        _activeCameraName = mostRecentCamera['name'] as String?;
      });

      debugPrint('Fetching image from camera: $cameraUrl');
      
      // Try up to 3 times with increasing delays
      Uint8List? imageBytes;
      for (int attempt = 1; attempt <= 3 && mounted; attempt++) {
        try {
          final response = await http.get(Uri.parse(cameraUrl))
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200 && 
              response.headers['content-type']?.contains('image/') == true) {
            imageBytes = response.bodyBytes;
            debugPrint('Image fetch successful on attempt $attempt');
            break;
          }
          
          debugPrint('Invalid response on attempt $attempt: ${response.statusCode}');
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        } catch (e) {
          debugPrint('Error on attempt $attempt: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      if (imageBytes != null && mounted) {
        setState(() {
          _latestImageBytes = imageBytes;
          _latestImage = imageBytes != null ? Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ) : null;
        });
        debugPrint('Image updated successfully');
      } else {
        debugPrint('Failed to fetch image after all attempts');
      }
    } catch (e) {
      debugPrint('Error in image fetch process: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingImage = false);
        debugPrint('Image fetch completed, _isFetchingImage set to false');
      }
    }
  }

  void _handleCameraRefresh(Map<String, dynamic> camera) {
    // Don't allow refresh if alert is visible or already fetching
    if (_alertVisible || _isFetchingImage) return;

    setState(() {
      _activeCameraUrl = camera['url'] as String?;
      _activeCameraName = camera['name'] as String?;
    });
    _fetchLatestImage(ref.read(securityStatusProvider));
  }

  Future<void> _showFullScreenImage() async {
    if (_latestImage == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: 'detection_image_fullscreen',
              child: _latestImage!,
            ),
          ),
        ),
      ),
    );
  }

  void _startImageUpdates() {
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(securityStatusProvider);
      _fetchLatestImage(status);
    });

    // Set up periodic updates every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_alertVisible && !_isFetchingImage) {
        final status = ref.read(securityStatusProvider);
        _fetchLatestImage(status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityStatusProvider);
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    // Listen for state changes and show notifications
    ref.listenManual(
      securityStatusProvider,
      (previous, next) {
        if (next.shouldShowNotification && !_alertVisible) {
          debugPrint('Attempting to fetch image and show alert...');
          _fetchLatestImage(next).then((_) {
            debugPrint('Image fetched, latestImage is ${_latestImage != null ? 'available' : 'null'}');
            if (mounted && _latestImage != null) {
              debugPrint('Showing detection alert...');
              _showDetectionAlert(next);
            }
          });
          ref.read(securityStatusProvider.notifier).acknowledgeNotification();
        }
      },
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepForestGreen.withOpacity(0.95),
              AppTheme.pineGreen.withOpacity(0.85),
              AppTheme.mistGray.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'logo',
                      child: Image.asset(
                        'assets/images/dssLogo.png',
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SecureScape',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Add IP Configuration Button
                    IconButton(
                      onPressed: () => _showIpConfigDialog(context),
                      icon: const Icon(Icons.settings_ethernet, color: Colors.white),
                      tooltip: 'Configure Gadget IP',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    if (securityState.isLoading)
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => ref.read(securityStatusProvider.notifier).checkStatus(),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.read(securityStatusProvider.notifier).checkStatus(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 24.0 : 16.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status Section
                          StatusCard(
                            status: securityState,
                            dateFormatter: _dateFormatter,
                            activeCameraName: _activeCameraName,
                            isLargeScreen: isLargeScreen,
                          ),
                          const SizedBox(height: 24),
                          
                          // Latest Capture Section
                          if (_latestImage != null) ...[
                            const SectionHeader(title: 'Latest Capture'),
                            const SizedBox(height: 12),
                            Center(
                              child: DetectionCard(
                                image: _latestImage!,
                                status: securityState,
                                dateFormatter: _dateFormatter,
                                activeCameraName: _activeCameraName,
                                onFullScreen: _showFullScreenImage,
                                isLargeScreen: isLargeScreen,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Connected Cameras Section
                          if (securityState.cameras.isNotEmpty) ...[
                            const SectionHeader(title: 'Connected Cameras'),
                            const SizedBox(height: 12),
                            CamerasList(
                              cameras: securityState.cameras,
                              dateFormatter: _dateFormatter,
                              onRefresh: _handleCameraRefresh,
                              isLargeScreen: isLargeScreen,
                            ),
                          ],
                          // Add extra padding at bottom for better scrolling
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.deepForestGreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 65,
          selectedIndex: 1,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.history, color: Colors.white),
              label: 'Logs',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.home, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.camera_alt, color: Colors.white),
              label: 'Cameras',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.build, color: Colors.white),
              label: 'Test',
            ),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LogsScreen(),
                  ),
                );
                break;
              case 1:
                // Already on home screen
                break;
              case 2:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CamerasScreen(),
                  ),
                );
                break;
              case 3:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const TestGadgetScreen(),
                  ),
                );
                break;
            }
          },
        ),
      ),
    );
  }

  Future<void> _showIpConfigDialog(BuildContext context) async {
    final currentIp = ref.read(gadgetIpProvider);
    final TextEditingController ipController = TextEditingController(text: currentIp);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Gadget IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.8.225',
                helperText: 'Enter the IP address of your SecureScape gadget',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIp = ipController.text.trim();
              if (_isValidIpAddress(newIp)) {
                // Update the IP
                ref.read(gadgetIpProvider.notifier).state = newIp;
                Navigator.pop(context);

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Connecting to gadget...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                // Trigger an immediate status check
                await ref.read(securityStatusProvider.notifier).checkStatus();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gadget IP updated to: $newIp'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid IP address'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isValidIpAddress(String ip) {
    if (ip.isEmpty) return false;
    
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    return parts.every((part) {
      try {
        final number = int.parse(part);
        return number >= 0 && number <= 255;
      } catch (e) {
        return false;
      }
    });
  }
}

class StatusCard extends ConsumerWidget {
  final SecurityState status;
  final DateFormat dateFormatter;
  final String? activeCameraName;
  final bool isLargeScreen;

  const StatusCard({
    Key? key,
    required this.status,
    required this.dateFormatter,
    required this.activeCameraName,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(ref),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusText(),
                          if (status.lastDetectionTime != null) ...[
                            const SizedBox(height: 4),
                            _buildTimestamp(),
                          ],
                          if (activeCameraName != null) ...[
                            const SizedBox(height: 4),
                            _buildCameraInfo(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(WidgetRef ref) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (status.personDetected ? Colors.red : Colors.green).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              status.personDetected ? Icons.warning : Icons.check_circle,
              color: status.personDetected ? Colors.red : Colors.green,
              size: isLargeScreen ? 48 : 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return Text(
      status.personDetected ? 'Person Detected!' : 'All Clear',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: isLargeScreen ? 24 : 20,
        fontFamily: 'SF Pro Display',
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      'Last Detection: ${dateFormatter.format(status.lastDetectionTime!)}',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: isLargeScreen ? 16 : 14,
        fontFamily: 'SF Pro Text',
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCameraInfo() {
    return Text(
      'Camera: ${activeCameraName?.replaceAll('camera_node', 'Node ') ?? 'Unknown'} Camera',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: isLargeScreen ? 14 : 12,
        fontFamily: 'SF Pro Text',
        letterSpacing: 0.3,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Display',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class CamerasList extends StatelessWidget {
  final List<Map<String, dynamic>> cameras;
  final DateFormat dateFormatter;
  final Function(Map<String, dynamic>) onRefresh;
  final bool isLargeScreen;

  const CamerasList({
    Key? key,
    required this.cameras,
    required this.dateFormatter,
    required this.onRefresh,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cameras.length,
        itemBuilder: (context, index) {
          final camera = cameras[index];
          final lastSeen = DateTime.fromMillisecondsSinceEpoch(
            camera['lastSeen'] ?? 0,
          );
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CameraCard(
              camera: camera,
              lastSeen: lastSeen,
              dateFormatter: dateFormatter,
              onRefresh: onRefresh,
              isLargeScreen: isLargeScreen,
            ),
          );
        },
      ),
    );
  }
}

class CameraCard extends StatelessWidget {
  final Map<String, dynamic> camera;
  final DateTime lastSeen;
  final DateFormat dateFormatter;
  final Function(Map<String, dynamic>) onRefresh;
  final bool isLargeScreen;

  const CameraCard({
    Key? key,
    required this.camera,
    required this.lastSeen,
    required this.dateFormatter,
    required this.onRefresh,
    required this.isLargeScreen,
  }) : super(key: key);

  String _getFormattedTimestamp() {
    // If lastSeen is too old (like epoch 0) or in the future, use current time
    final now = DateTime.now();
    if (lastSeen.year < 2020 || lastSeen.isAfter(now)) {
      return 'Last seen: Just now';
    }

    final difference = now.difference(lastSeen);
    if (difference.inSeconds < 60) {
      return 'Last seen: Just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen: ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen: ${difference.inHours}h ago';
    } else {
      return 'Last seen: ${dateFormatter.format(lastSeen)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onRefresh(camera),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.pineGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: isLargeScreen ? 28 : 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      camera['name'] ?? 'Unknown Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isLargeScreen ? 14 : 12,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedTimestamp(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isLargeScreen ? 12 : 10,
                        fontFamily: 'SF Pro Text',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetectionCard extends StatelessWidget {
  final Image image;
  final SecurityState status;
  final DateFormat dateFormatter;
  final String? activeCameraName;
  final VoidCallback onFullScreen;
  final bool isLargeScreen;

  const DetectionCard({
    Key? key,
    required this.image,
    required this.status,
    required this.dateFormatter,
    required this.activeCameraName,
    required this.onFullScreen,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeCameraName != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.pineGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeCameraName?.replaceAll('camera_node', 'Node ') ?? 'Unknown'} Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ),
              Hero(
                tag: 'detection_image',
                child: GestureDetector(
                  onTap: onFullScreen,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: image,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (status.lastDetectionTime != null)
                      Expanded(
                        child: Text(
                          dateFormatter.format(status.lastDetectionTime!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isLargeScreen ? 14 : 12,
                            fontFamily: 'SF Pro Text',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: isLargeScreen ? 28 : 24,
                      ),
                      onPressed: onFullScreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
