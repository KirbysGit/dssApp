import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_provider.dart';
import '../models/security_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Image? _latestImage;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showDetectionAlert(SecurityState status) async {
    if (_alertVisible || !mounted) return;

    _alertVisible = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Person Detected!',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activeCameraName != null)
                  Text(
                    'Camera: $_activeCameraName',
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Detection Time: ${status.lastDetectionTime != null ? _dateFormatter.format(status.lastDetectionTime!) : "Unknown"}',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_latestImage != null)
                  Hero(
                    tag: 'detection_image',
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _latestImage!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  color: AppTheme.deepForestGreen,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Add emergency response action
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Emergency Response',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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

    // If we're already showing an alert or fetching an image, don't fetch again
    if (_alertVisible || _isFetchingImage) {
      debugPrint('Alert visible or already fetching image, skipping fetch');
      return;
    }

    debugPrint('Starting image fetch...');
    _isFetchingImage = true;

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
      final response = await http.get(Uri.parse(cameraUrl))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200 && mounted) {
        debugPrint('Image fetched successfully');
        setState(() {
          _latestImage = Image.memory(
            response.bodyBytes,
            fit: BoxFit.contain,
          );
        });
      } else {
        debugPrint('Failed to fetch image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingImage = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityStatusProvider);
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    // Listen for state changes and show notifications
    ref.listenManual(
      securityStatusProvider,
      (previous, next) {
        debugPrint('Security state changed:');
        debugPrint('Previous detection time: ${previous?.lastDetectionTime}');
        debugPrint('Next detection time: ${next.lastDetectionTime}');
        debugPrint('Should show notification: ${next.shouldShowNotification}');
        debugPrint('Alert visible: $_alertVisible');

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
              ModernAppBar(
                isLoading: securityState.isLoading,
                onRefresh: () => ref.read(securityStatusProvider.notifier).checkStatus(),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.read(securityStatusProvider.notifier).checkStatus(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFadeTransition(
                        opacity: _fadeAnimation,
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? 24.0 : 16.0,
                              vertical: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusCard(
                                  status: securityState,
                                  dateFormatter: _dateFormatter,
                                  activeCameraName: _activeCameraName,
                                  isLargeScreen: isLargeScreen,
                                ),
                                const SizedBox(height: 24),
                                
                                if (securityState.cameras.isNotEmpty) ...[
                                  const SectionHeader(title: 'Connected Cameras'),
                                  const SizedBox(height: 12),
                                  CamerasList(
                                    cameras: securityState.cameras,
                                    dateFormatter: _dateFormatter,
                                    onRefresh: _handleCameraRefresh,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                
                                if (_latestImage != null) ...[
                                  const SectionHeader(title: 'Latest Detection'),
                                  const SizedBox(height: 12),
                                  DetectionCard(
                                    image: _latestImage!,
                                    status: securityState,
                                    dateFormatter: _dateFormatter,
                                    activeCameraName: _activeCameraName,
                                    onFullScreen: _showFullScreenImage,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernAppBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const ModernAppBar({
    Key? key,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(width: 12),
          Text(
            'Security Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStatusIcon(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
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
      'Camera: $activeCameraName',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: isLargeScreen ? 16 : 14,
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
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'SF Pro Display',
        letterSpacing: 0.8,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              Hero(
                tag: 'detection_image',
                child: GestureDetector(
                  onTap: onFullScreen,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status.lastDetectionTime != null)
                            Text(
                              'Captured: ${dateFormatter.format(status.lastDetectionTime!)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargeScreen ? 14 : 12,
                                fontFamily: 'SF Pro Text',
                                letterSpacing: 0.3,
                              ),
                            ),
                          if (activeCameraName != null)
                            Text(
                              'Camera: $activeCameraName',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isLargeScreen ? 14 : 12,
                                fontFamily: 'SF Pro Text',
                                letterSpacing: 0.3,
                              ),
                            ),
                        ],
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
