// lib/screens/dashboard_screen.dart

// Dashboard Screen.

// Responsibilities:
// - Display the Latest Image From The Camera.
// - Display the Status of the Security System.
// - Allow the User to Configure the IP Address of the Gadget.
// - Allow the User to Refresh the Status of the Security System.


// Imports.
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local Imports.
import './logs_screen.dart';
import './alert_screen.dart';
import './cameras_screen.dart';
import '../theme/app_theme.dart';
import './test_gadget_screen.dart';
import '../widgets/status_card.dart';
import '../models/security_state.dart';
import '../widgets/section_header.dart';
import '../providers/security_provider.dart';
import '../services/camera_image_service.dart';
import '../widgets/cameras_list.dart' as widgets;
import '../services/notification_service.dart';

// Dashboard Screen.
class DashboardScreen extends ConsumerStatefulWidget {
  // Constructor.
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

// Dashboard Screen State.
class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  // Animation Controller.
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Latest Image.
  Image? _latestImage;
  Uint8List? _latestImageBytes;

  // Alert Visible.
  bool _alertVisible = false;
  DateTime? _lastAlertTime;

  // Date Formatter.
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy, hh:mm a');

  // Active Camera URL.
  String? _activeCameraUrl;

  // Active Camera Name.
  String? _activeCameraName;

  // Is Fetching Image.
  bool _isFetchingImage = false;

  final _cameraService = CameraImageService();

  @override
  void initState() {
    // Initialize The Animation Controller.
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Create The Fade Animation.
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Forward The Animation.
    _animationController.forward();

    // Start Periodic Image Updates.
    _startImageUpdates();
  }

  @override
  void dispose() {
    // Dispose The Animation Controller.
    _animationController.dispose();

    // Dispose The State.
    super.dispose();
  }

  // Fetch Latest Image.
  Future<void> _fetchLatestImage(SecurityState status) async {
    if (_isFetchingImage) {
      debugPrint('🔄 Already fetching image, skipping...');
      return;
    }

    setState(() {
      _isFetchingImage = true;
    });

    try {
      final (imageBytes, _, cameraName) = await _cameraService.fetchLatestImage(status);
      
      if (!mounted) return;

      if (imageBytes != null) {
        setState(() {
          _latestImageBytes = imageBytes;
          _latestImage = Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
          _activeCameraName = cameraName;
          _isFetchingImage = false;
        });
      } else {
        debugPrint('⚠️ No image data received');
        setState(() {
          _isFetchingImage = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _fetchLatestImage: $e');
      if (mounted) {
        setState(() {
          _isFetchingImage = false;
        });
      }
    }
  }

  // Show Detection Alert.
  Future<void> _showDetectionAlert(SecurityState status) async {
    if (_alertVisible || !mounted) {
      debugPrint('⚠️ Alert already visible or widget unmounted');
      return;
    }

    setState(() {
      _alertVisible = true;
    });

    try {
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
      );
    } finally {
      if (mounted) {
        setState(() {
          _alertVisible = false;
        });
      }
    }
  }

  // Handle Camera Refresh.
  void _handleCameraRefresh(Map<String, dynamic> camera) {
    // If The Alert Is Visible Or The State Is Not Mounted, Return.
    if (_alertVisible || _isFetchingImage) return;

    // Set The Active Camera URL And Name.
    setState(() {
      _activeCameraUrl = camera['url'] as String?;
      _activeCameraName = camera['name'] as String?;
    });

    // Fetch The Latest Image.
    _fetchLatestImage(ref.read(securityStatusProvider));
  }

  // Show Full Screen Image.
  Future<void> _showFullScreenImage() async {
    // If The Latest Image Is Null, Return.
    if (_latestImage == null) return;

    // Show The Full Screen Image.
    await Navigator.of(context).push(
      // Material Page Route.
      MaterialPageRoute(
        // Builder.
        builder: (context) => Scaffold(
          // Background Color.
          backgroundColor: Colors.black,
          // App Bar.
          appBar: AppBar(
            // Background Color.
            backgroundColor: Colors.black,
            // Icon Theme.
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

  // Start Image Updates.
  void _startImageUpdates() {
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestImage(ref.read(securityStatusProvider));
    });

    // Set up periodic updates every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_alertVisible) {
        _fetchLatestImage(ref.read(securityStatusProvider));
      }
    });
  }

  // Build The Widget.
  @override
  Widget build(BuildContext context) {
    // Security State.
    final securityState = ref.watch(securityStatusProvider);

    // Size.
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    // Listen For State Changes And Show Notifications.
    ref.listenManual(
      securityStatusProvider,
      (previous, next) {
        if (next.shouldShowNotification && !_alertVisible) {
          // Check if we've shown an alert recently (within last 15 seconds)
          final now = DateTime.now();
          if (_lastAlertTime != null && 
              now.difference(_lastAlertTime!).inSeconds < 15) {
            debugPrint('🔄 Skipping alert - too soon since last alert');
            return;
          }

          debugPrint('🚨 Showing detection alert and system notification...');
          setState(() {
            _lastAlertTime = now;
          });

          // First show the system notification
          NotificationService().showNotification(
            title: '🚨 Person Detected!',
            body: 'A person has been detected by your security system.',
            cameraName: next.cameras.isNotEmpty ? next.cameras.first['name'] : null,
            cameraUrl: next.cameras.isNotEmpty ? next.cameras.first['url'] : null,
          );

          // Then fetch image and show in-app alert
          _fetchLatestImage(next).then((_) {
            if (mounted && _latestImage != null) {
              debugPrint('📸 Image fetched successfully, displaying in-app alert');
              _showDetectionAlert(next);
            } else {
              debugPrint('❌ Failed to show in-app alert: mounted=$mounted, hasImage=${_latestImage != null}');
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
                              child: widgets.DetectionCard(
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
                            widgets.CamerasList(
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
                hintText: '192.168.8.207',
                helperText: 'Enter the IP address of your SecureScape gadget',
                prefixIcon: Icon(Icons.router),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Default IP: 192.168.8.207',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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

  // Validate IP Address.
  bool _isValidIpAddress(String ip) {
    // If The IP Is Empty, Return False.
    if (ip.isEmpty) return false;
    
    // Split The IP Address.
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    // Validate Each Part.
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
