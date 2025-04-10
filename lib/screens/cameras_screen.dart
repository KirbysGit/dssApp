import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/security_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/rendering.dart';
import './dashboard_screen.dart';
import './logs_screen.dart';
import './test_gadget_screen.dart';

class CamerasScreen extends ConsumerStatefulWidget {
  const CamerasScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends ConsumerState<CamerasScreen> {
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy, hh:mm a');
  bool _isLoading = false;

  Future<void> _refreshCameras() async {
    setState(() => _isLoading = true);
    await ref.read(securityStatusProvider.notifier).checkStatus();
    setState(() => _isLoading = false);
  }

  Future<void> _captureImage(String cameraUrl) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(cameraUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && 
          response.headers['content-type']?.contains('image/') == true) {
        final capturedImage = Image.memory(
          response.bodyBytes,
          fit: BoxFit.contain,
        );

        if (mounted) {
          await _showCapturedImageDialog(capturedImage);
          _showSuccessMessage('Image captured successfully');
        }
      } else {
        throw Exception('Invalid image format received');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to capture image: ${e.toString()}');
      }
      debugPrint('Error capturing image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCapturedImageDialog(Image capturedImage) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: capturedImage,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Captured: ${_dateFormatter.format(DateTime.now())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityStatusProvider);
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

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
              _buildHeader(isLargeScreen),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCameras,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24.0 : 16.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Live Camera Feeds'),
                        const SizedBox(height: 16),
                        securityState.cameras.isEmpty
                            ? _buildEmptyState()
                            : CamerasList(
                                cameras: securityState.cameras,
                                dateFormatter: _dateFormatter,
                                onRefresh: (camera) => _captureImage(camera['url'] as String),
                                isLargeScreen: isLargeScreen,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camera Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLargeScreen ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              Text(
                'Monitor and capture from your cameras',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isLoading)
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
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshCameras,
              tooltip: 'Refresh Cameras',
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Display',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_off,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Cameras Connected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect a camera to start monitoring',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshCameras,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepForestGreen.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
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
        selectedIndex: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _buildNavDestination(Icons.history_outlined, Icons.history, 'Logs'),
          _buildNavDestination(Icons.home_outlined, Icons.home, 'Home'),
          _buildNavDestination(Icons.camera_alt_outlined, Icons.camera_alt, 'Cameras'),
          _buildNavDestination(Icons.build_outlined, Icons.build, 'Utility'),
        ],
        onDestinationSelected: (index) => _handleNavigation(context, index),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(outlinedIcon, color: Colors.white.withOpacity(0.7)),
      selectedIcon: Icon(filledIcon, color: Colors.white),
      label: label,
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final routes = [
      const LogsScreen(),
      const DashboardScreen(),
      const CamerasScreen(),
      const TestGadgetScreen(),
    ];

    if (index != 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => routes[index],
        ),
      );
    }
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLargeScreen ? 2 : 1,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cameras.length,
      itemBuilder: (context, index) {
        final camera = cameras[index];
        return CameraCard(
          camera: camera,
          dateFormatter: dateFormatter,
          isLargeScreen: isLargeScreen,
          onCapture: () => onRefresh(camera),
        );
      },
    );
  }
}

class CameraCard extends StatefulWidget {
  final Map<String, dynamic> camera;
  final DateFormat dateFormatter;
  final bool isLargeScreen;
  final VoidCallback onCapture;

  const CameraCard({
    Key? key,
    required this.camera,
    required this.dateFormatter,
    required this.isLargeScreen,
    required this.onCapture,
  }) : super(key: key);

  @override
  State<CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<CameraCard> {
  Timer? _previewTimer;
  Image? _previewImage;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    _startPreviewUpdates();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _startPreviewUpdates() {
    // Initial preview load
    _updatePreview();
    
    // Set up periodic updates every 5 seconds
    _previewTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updatePreview();
      }
    });
  }

  Future<void> _updatePreview() async {
    if (_isLoadingPreview) return;

    setState(() => _isLoadingPreview = true);

    try {
      final cameraUrl = widget.camera['url'] as String?;
      if (cameraUrl == null) return;

      final response = await http.get(Uri.parse(cameraUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && 
          response.headers['content-type']?.contains('image/') == true) {
        if (mounted) {
          setState(() {
            _previewImage = Image.memory(
              response.bodyBytes,
              fit: BoxFit.cover,
              // Use gapless playback to prevent flickering during updates
              gaplessPlayback: true,
            );
            _isLoadingPreview = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating preview: $e');
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  String _getFormattedTimestamp() {
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(
      widget.camera['lastSeen'] as int? ?? 0,
    );
    
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
      return 'Last seen: ${widget.dateFormatter.format(lastSeen)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,  // Take full width
      constraints: const BoxConstraints(maxHeight: 400),
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
              // Camera Preview Section
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Preview Image or Placeholder
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: _previewImage != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: _previewImage!,
                            )
                          : const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                    ),
                    // Loading Indicator
                    if (_isLoadingPreview)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Camera Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.camera['name'] as String? ?? 'Unknown Camera',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.isLargeScreen ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getFormattedTimestamp(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: widget.isLargeScreen ? 14 : 12,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: widget.onCapture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepForestGreen.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.camera),
                          label: const Text('Capture'),
                        ),
                      ],
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