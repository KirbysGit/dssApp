import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.deepForestGreen.withOpacity(0.9),
                  AppTheme.pineGreen.withOpacity(0.7),
                  AppTheme.mistGray,
                ],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? size.width * 0.1 : 24.0,
                  vertical: size.height * 0.05,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Title Section
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Hero(
                              tag: 'logo',
                              child: Image.asset(
                                'assets/images/dssLogo.png',
                                height: isLargeScreen ? 200 : 150,
                              ),
                            ),
                            const SizedBox(height: 24),
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
                            const SizedBox(height: 16),
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

                    SizedBox(height: size.height * 0.08),

                    // Action Buttons Section
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
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            context: context,
                            icon: Icons.info_outline,
                            label: 'About SecureScape',
                            description: 'Learn more about our security solution',
                            onPressed: () => Navigator.pushNamed(context, '/about'),
                            isSecondary: true,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.08),

                    // Footer Section
                    FadeTransition(
                      opacity: _fadeInAnimation,
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
                  ],
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
          ),
          child: Row(
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
        ),
      ),
    );
  }
} 