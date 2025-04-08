import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Tilt effect variables
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  final List<ParticleData> _particles = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize particle system
    for (int i = 0; i < 20; i++) {
      _particles.add(ParticleData(
        position: Offset(
          Random().nextDouble() * 400,
          Random().nextDouble() * 800,
        ),
        velocity: Offset(
          Random().nextDouble() * 2 - 1,
          Random().nextDouble() * 2 - 1,
        ),
        size: Random().nextDouble() * 4 + 2,
      ));
    }
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..repeat();

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutQuart),
    ));

    _backgroundController.forward();
    
    // Listen to accelerometer events for tilt effect
    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _tiltX = event.y.clamp(-0.5, 0.5) * 0.1;
          _tiltY = event.x.clamp(-0.5, 0.5) * 0.1;
        });
      }
    });
    
    // Start particle animation
    _particleController.addListener(_updateParticles);
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.position += particle.velocity;
      
      // Wrap particles around screen
      if (particle.position.dx < 0) particle.position = Offset(400, particle.position.dy);
      if (particle.position.dx > 400) particle.position = Offset(0, particle.position.dy);
      if (particle.position.dy < 0) particle.position = Offset(particle.position.dx, 800);
      if (particle.position.dy > 800) particle.position = Offset(particle.position.dx, 0);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static Background with Gradient
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
                    stops: [0.0, _backgroundController.value, 1.0],
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

          // Particle System
          CustomPaint(
            painter: ParticlePainter(particles: _particles),
          ),

          // Main Content with 3D Tilt
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            alignment: Alignment.center,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? size.width * 0.1 : 24.0,
                    vertical: size.height * 0.05,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title Section with Enhanced Animation
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Animated Logo with Glow
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.pineGreen.withOpacity(0.3 * _pulseController.value),
                                          blurRadius: 30 * _pulseController.value,
                                          spreadRadius: 5 * _pulseController.value,
                                        ),
                                      ],
                                    ),
                                    child: Hero(
                                      tag: 'logo',
                                      child: Image.asset(
                                        'assets/images/dssLogo.png',
                                        height: isLargeScreen ? 200 : 150,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Title with Glassmorphism
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Welcome to SecureScape',
                                          style: TextStyle(
                                            fontSize: isLargeScreen ? 36 : 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Your Portable Security Solution',
                                          style: TextStyle(
                                            fontSize: isLargeScreen ? 20 : 16,
                                            color: Colors.white.withOpacity(0.9),
                                            letterSpacing: 0.5,
                                            fontFamily: 'SF Pro Text',
                                          ),
                                          textAlign: TextAlign.center,
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

                      SizedBox(height: size.height * 0.08),

                      // Action Buttons with Enhanced Animation
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Column(
                          children: [
                            _buildActionButton(
                              context: context,
                              icon: Icons.link,
                              label: 'Pair Your SecureScape',
                              description: 'Connect and configure your security device',
                              onPressed: () => Navigator.pushNamed(context, '/connecting'),
                            ).animate()
                              .fadeIn(delay: const Duration(milliseconds: 400))
                              .slideX(begin: -0.2, end: 0),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              context: context,
                              icon: Icons.info_outline,
                              label: 'About SecureScape',
                              description: 'Learn more about our security solution',
                              onPressed: () => Navigator.pushNamed(context, '/about'),
                              isSecondary: true,
                            ).animate()
                              .fadeIn(delay: const Duration(milliseconds: 600))
                              .slideX(begin: 0.2, end: 0),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 0.08),

                      // Footer with Animated Gradient
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Secure your space, anywhere.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                  fontFamily: 'SF Pro Text',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '© 2024 SecureScape',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                  fontFamily: 'SF Pro Text',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ).animate()
                        .fadeIn(delay: const Duration(milliseconds: 800))
                        .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSecondary ? Colors.white.withOpacity(0.3) : Colors.transparent,
              width: 2,
            ),
            color: isSecondary 
              ? Colors.white.withOpacity(0.1)
              : AppTheme.pineGreen.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: (isSecondary ? Colors.black : AppTheme.pineGreen).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Button content
              Row(
                children: [
                  Icon(
                    icon,
                    size: isLargeScreen ? 32 : 24,
                    color: Colors.white.withOpacity(isSecondary ? 0.9 : 1),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isLargeScreen ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: isLargeScreen ? 14 : 12,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: isLargeScreen ? 24 : 20,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
              // Hover effect overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      splashColor: Colors.white.withOpacity(0.1),
                      highlightColor: Colors.white.withOpacity(0.05),
                    ),
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

// Particle System Classes
class ParticleData {
  Offset position;
  Offset velocity;
  final double size;

  ParticleData({
    required this.position,
    required this.velocity,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final List<ParticleData> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
} 