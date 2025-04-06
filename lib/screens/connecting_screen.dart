import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import './dashboard_screen.dart';
import './welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_provider.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  int _connectionStep = 0;
  bool _showTroubleshooting = false;
  final List<String> _connectionSteps = [
    'Initializing SecureScape...',
    'Checking WiFi connection...',
    'Verifying network...',
    'Connecting to SecureScape network...',
    'Establishing secure connection...',
    'Almost there...',
  ];
  Timer? _stepTimer;
  Timer? _dotsTimer;
  Timer? _connectionCheckTimer;
  String _dots = '';
  double _progress = 0.0;
  int _connectionAttempts = 0;
  static const int MAX_CONNECTION_ATTEMPTS = 3;
  static const String REQUIRED_NETWORK = "GL-AR300M-aa7-NOR";
  
  // Add animations for step transitions
  late AnimationController _stepAnimationController;
  late Animation<double> _stepAnimation;

  // Add new controllers for enhanced animations
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  bool _showDetails = false;

  final TextEditingController _ipController = TextEditingController(text: '192.168.8.225');

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize step animation controller
    _stepAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stepAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.easeIn,
    ));

    // Initialize new animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Show IP input dialog before starting connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gadgetIp = ref.read(gadgetIpProvider);
      if (gadgetIp.isEmpty || !_isValidIpAddress(gadgetIp)) {
        _showIpInputDialog();
      } else {
        _startConnectionProcess();
      }
    });
    
    // Animate the dots
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dots = _dots.length >= 3 ? '' : _dots + '.';
        });
      }
    });
  }

  Future<bool> _checkNetworkConnection() async {
    try {
      // Request location permission (required for WiFi info on Android)
      var locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        debugPrint('Location permission denied');
        return false;
      }

      final networkInfo = NetworkInfo();
      final wifiName = await networkInfo.getWifiName();
      debugPrint('Current WiFi network: $wifiName');

      // Remove quotes and null check
      final cleanWifiName = wifiName?.replaceAll('"', '') ?? '';
      debugPrint('Cleaned WiFi name: $cleanWifiName');
      
      if (cleanWifiName == REQUIRED_NETWORK) {
        debugPrint('Connected to correct network');
        return true;
      } else {
        debugPrint('Connected to wrong network: $cleanWifiName');
        debugPrint('Expected network: $REQUIRED_NETWORK');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking network: $e');
      return false;
    }
  }

  void _startConnectionProcess() {
    const stepDuration = Duration(seconds: 2);
    _connectionAttempts = 0;
    
    _checkAndProceed();

    // Set up periodic connection check
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkAndProceed();
      }
    });
  }

  Future<void> _checkAndProceed() async {
    if (_connectionAttempts >= MAX_CONNECTION_ATTEMPTS) {
      _navigateToWelcome();
      return;
    }

    // Check if we have a valid IP address
    final gadgetIp = ref.read(gadgetIpProvider);
    if (gadgetIp.isEmpty || !_isValidIpAddress(gadgetIp)) {
      _showIpInputDialog();
      return;
    }

    // Check location permission first
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return;
    }

    final isConnected = await _checkNetworkConnection();
    if (!isConnected) {
      setState(() {
        _connectionAttempts++;
        _connectionStep = 1; // Reset to "Checking WiFi connection" step
        _progress = (_connectionStep + 1) / _connectionSteps.length;
      });

      if (_connectionAttempts >= MAX_CONNECTION_ATTEMPTS) {
        _showConnectionError();
      }
    } else {
      _proceedWithConnection();
    }
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

  void _proceedWithConnection() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          if (_connectionStep < _connectionSteps.length - 1) {
            _connectionStep++;
            _progress = (_connectionStep + 1) / _connectionSteps.length;
            HapticFeedback.lightImpact();
          } else {
            timer.cancel();
            _navigateToDashboard();
          }
        });
      }
    });
  }

  void _showConnectionError() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to connect to the SecureScape network.'),
              const SizedBox(height: 16),
              Text('Please ensure you are connected to:\n"$REQUIRED_NETWORK"'),
              const SizedBox(height: 16),
              const Text('You will be redirected to the welcome screen.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToWelcome();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SecureScape needs location permission to:'),
              SizedBox(height: 8),
              Text('• Verify connection to the correct network'),
              Text('• Ensure secure communication with devices'),
              SizedBox(height: 16),
              Text('Please enable location permission in settings.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToWelcome();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _navigateToDashboard() async {
    _cleanupTimers();
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _navigateToWelcome() {
    _cleanupTimers();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    }
  }

  void _cleanupTimers() {
    _stepTimer?.cancel();
    _dotsTimer?.cancel();
    _connectionCheckTimer?.cancel();
  }

  void _toggleTroubleshooting() {
    setState(() {
      _showTroubleshooting = !_showTroubleshooting;
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _cleanupTimers();
    _backgroundController.dispose();
    _stepAnimationController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Setting up secure communication channels...';
      case 1:
        return 'Checking your WiFi connection status...';
      case 2:
        return 'Making sure you\'re on the correct network...';
      case 3:
        return 'Establishing connection to SecureScape...';
      case 4:
        return 'Setting up encrypted communication...';
      case 5:
        return 'Finalizing connection setup...';
      default:
        return '';
    }
  }

  Widget _buildConnectionCard(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            children: [
              // Connection Steps Indicator with Icons
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _connectionSteps.length,
                    (index) => _buildStepIndicatorWithIcon(index),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Lottie Animation based on connection state
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: isLargeScreen ? 120 : 100,
                        height: isLargeScreen ? 120 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.pineGreen.withOpacity(0.2 * _pulseController.value),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Main connection animation
                  SizedBox(
                    width: isLargeScreen ? 100 : 80,
                    height: isLargeScreen ? 100 : 80,
                    child: Lottie.asset(
                      'assets/animations/connecting.json',
                      fit: BoxFit.contain,
                      animate: true,
                    ),
                  ),

                  // Rotating outer ring
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateController.value * 2 * pi,
                        child: Container(
                          width: isLargeScreen ? 110 : 90,
                          height: isLargeScreen ? 110 : 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.pineGreen.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Current Step Text with Enhanced Animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey<int>(_connectionStep),
                  children: [
                    Text(
                      _connectionSteps[_connectionStep] + _dots,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_showDetails) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getStepDescription(_connectionStep),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isLargeScreen ? 14 : 12,
                          fontFamily: 'SF Pro Text',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Network Information with Enhanced Styling
              if (_connectionStep >= 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        REQUIRED_NETWORK,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: Colors.white.withOpacity(0.6),
                          size: 16,
                        ),
                        onPressed: () => setState(() => _showDetails = !_showDetails),
                        tooltip: 'Show connection details',
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn()
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Enhanced Progress Bar
              Stack(
                children: [
                  // Background progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.pineGreen.withOpacity(0.8),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  // Animated gradient overlay
                  if (_progress > 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedBuilder(
                          animation: _backgroundController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: _progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0),
                                    ],
                                    stops: [
                                      0.0,
                                      _backgroundController.value,
                                      1.0,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Percentage with Animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  key: ValueKey<int>((_progress * 100).toInt()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isLargeScreen ? 16 : 14,
                    fontFamily: 'SF Pro Text',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicatorWithIcon(int index) {
    final isCompleted = index < _connectionStep;
    final isCurrent = index == _connectionStep;
    
    IconData getStepIcon() {
      switch (index) {
        case 0:
          return Icons.power_settings_new;
        case 1:
          return Icons.wifi_find;
        case 2:
          return Icons.verified_user;
        case 3:
          return Icons.link;
        case 4:
          return Icons.security;
        case 5:
          return Icons.check_circle;
        default:
          return Icons.circle;
      }
    }

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppTheme.pineGreen
                  : isCurrent
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isCompleted || isCurrent
                    ? AppTheme.pineGreen
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              getStepIcon(),
              size: 16,
              color: isCompleted
                  ? Colors.white
                  : Colors.white.withOpacity(isCurrent ? 0.8 : 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: isCompleted
                ? AppTheme.pineGreen
                : Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background with Gradient Waves
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.deepForestGreen.withOpacity(0.95),
                      AppTheme.pineGreen.withOpacity(0.85),
                      AppTheme.mistGray.withOpacity(0.9),
                    ],
                    stops: [
                      0.0,
                      _backgroundController.value,
                      1.0,
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: WavesPainter(
                    animation: _backgroundController,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 48.0 : 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: size.height * 0.05),
                    // Animated Logo
                    Hero(
                      tag: 'logo',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.pineGreen.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/dssLogo.png',
                          height: isLargeScreen ? 120 : 80,
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: const Duration(milliseconds: 600))
                      .scale(delay: const Duration(milliseconds: 200)),
                    
                    const SizedBox(height: 48),

                    // Use the new connection card
                    _buildConnectionCard(isLargeScreen),

                    const SizedBox(height: 24),

                    // Help Button with Animation
                    TextButton.icon(
                      onPressed: _toggleTroubleshooting,
                      icon: Icon(
                        _showTroubleshooting ? Icons.close : Icons.help_outline,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      label: Text(
                        _showTroubleshooting ? 'Hide Tips' : 'Need Help?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isLargeScreen ? 16 : 14,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: const Duration(milliseconds: 800)),

                    // Troubleshooting Tips with Enhanced Animation
                    if (_showTroubleshooting)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: Colors.white,
                                  size: isLargeScreen ? 24 : 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Troubleshooting Tips',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isLargeScreen ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedTip(
                              '• Ensure you\'re connected to the SecureScape WiFi network',
                              delay: 0,
                            ),
                            _buildAnimatedTip(
                              '• Check if the SecureScape device is powered on',
                              delay: 100,
                            ),
                            _buildAnimatedTip(
                              '• Try restarting the SecureScape device',
                              delay: 200,
                            ),
                            _buildAnimatedTip(
                              '• Verify your network settings',
                              delay: 300,
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTip(String text, {required int delay}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
          fontFamily: 'SF Pro Text',
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: delay))
      .slideX(begin: 0.2, end: 0);
  }

  Future<void> _showIpInputDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Gadget IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.8.225',
                errorMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the IP address of the gadget you want to connect to.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final ip = _ipController.text.trim();
              if (_isValidIpAddress(ip)) {
                ref.read(gadgetIpProvider.notifier).state = ip;
                Navigator.pop(context);
                _startConnectionProcess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid IP address (e.g., 192.168.8.225)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for animated background waves
class WavesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavesPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveCount = 3;

    for (var i = 0; i < waveCount; i++) {
      final waveOffset = animation.value * size.width + (i * size.width / waveCount);
      path.moveTo(0, size.height * 0.5);
      
      for (var x = 0.0; x < size.width; x += 1) {
        final y = sin((x + waveOffset) * 0.02) * waveHeight + size.height * 0.5;
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavesPainter oldDelegate) => true;
} 