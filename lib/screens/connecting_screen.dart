import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import './dashboard_screen.dart';

class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({Key? key}) : super(key: key);

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  int _connectionStep = 0;
  bool _showTroubleshooting = false;
  final List<String> _connectionSteps = [
    'Initializing SecureScape...',
    'Checking WiFi connection...',
    'Connecting to SecureScape network...',
    'Establishing secure connection...',
    'Almost there...',
  ];
  Timer? _stepTimer;
  Timer? _dotsTimer;
  String _dots = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Start the connection process
    _startConnectionProcess();
    
    // Animate the dots
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dots = _dots.length >= 3 ? '' : _dots + '.';
        });
      }
    });
  }

  void _startConnectionProcess() {
    const stepDuration = Duration(seconds: 2);
    _stepTimer = Timer.periodic(stepDuration, (timer) {
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

  Future<void> _navigateToDashboard() async {
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

  void _toggleTroubleshooting() {
    setState(() {
      _showTroubleshooting = !_showTroubleshooting;
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _stepTimer?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
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
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 48.0 : 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/dssLogo.png',
                      height: isLargeScreen ? 120 : 80,
                    ),
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .scale(delay: const Duration(milliseconds: 200)),
                  
                  const SizedBox(height: 48),

                  // Connection Progress
                  Container(
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
                            // Loading Animation
                            LoadingAnimationWidget.discreteCircle(
                              color: Colors.white,
                              size: isLargeScreen ? 64 : 48,
                              secondRingColor: AppTheme.pineGreen,
                              thirdRingColor: AppTheme.mistGray,
                            ),
                            const SizedBox(height: 24),

                            // Progress Text
                            Text(
                              _connectionSteps[_connectionStep] + _dots,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargeScreen ? 20 : 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SF Pro Display',
                              ),
                            ).animate()
                              .fadeIn()
                              .scale(),

                            const SizedBox(height: 16),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.pineGreen,
                                ),
                                minHeight: 6,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Progress Percentage
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isLargeScreen ? 16 : 14,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: const Duration(milliseconds: 400))
                    .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 24),

                  // Help Button
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

                  // Troubleshooting Tips
                  if (_showTroubleshooting)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Troubleshooting Tips:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTroubleshootingTip(
                            '• Ensure you\'re connected to the SecureScape WiFi network',
                          ),
                          _buildTroubleshootingTip(
                            '• Check if the SecureScape device is powered on',
                          ),
                          _buildTroubleshootingTip(
                            '• Try restarting the SecureScape device',
                          ),
                          _buildTroubleshootingTip(
                            '• Verify your network settings',
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
        ],
      ),
    );
  }

  Widget _buildTroubleshootingTip(String text) {
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
    );
  }
} 