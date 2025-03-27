import 'dart:ui';
import 'dart:math' show pi, sin, cos;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _parallaxController;
  final ScrollController _scrollController = ScrollController();
  Offset _parallaxOffset = Offset.zero;
  double _scrollOffset = 0;
  Map<String, bool> _expandedTeamMembers = {};

  @override
  void initState() {
    super.initState();
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Initialize all team members as not expanded
    for (var member in _teamMembers) {
      _expandedTeamMembers[member['name'] as String] = false;
    }
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateParallaxOffset(DragUpdateDetails details) {
    setState(() {
      _parallaxOffset += details.delta;
      // Limit the parallax effect
      _parallaxOffset = Offset(
        _parallaxOffset.dx.clamp(-100.0, 100.0),
        _parallaxOffset.dy.clamp(-100.0, 100.0),
      );
    });
  }

  Widget _buildAnimatedSection(Widget child) {
    return child.animate()
      .fadeIn(duration: 400.ms)
      .slide(begin: const Offset(-0.2, 0), end: const Offset(0, 0));
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // You can use intl package to format any dates if needed
  static const String _aboutText = '''
SecureScape is a portable security system designed to provide reliable protection in remote areas. Whether you're camping, hiking, or securing a temporary location, our system offers real-time motion detection, image processing, and instant mobile notifications—even in areas without traditional network coverage.
''';

  static const String _missionText = '''
Our mission is to enhance personal security in unpredictable environments through advanced embedded systems, image recognition, and efficient communication protocols. SecureScape is built to be lightweight, easy to deploy, and effective in various conditions.
''';

  static const List<Map<String, String>> _features = [
    {
      'title': 'Motion Detection',
      'description': 'Detects movement using IR sensors and ESP32‑CAM modules.',
      'icon': 'motion_photos_on'
    },
    {
      'title': 'Real‑Time Alerts',
      'description': 'Notifies users instantly through the mobile app.',
      'icon': 'notifications_active'
    },
    {
      'title': 'Image Processing',
      'description': 'Identifies potential threats with machine learning models.',
      'icon': 'camera_alt'
    },
    {
      'title': 'Portable & Reliable',
      'description': 'Works in remote locations with minimal power usage.',
      'icon': 'battery_std'
    },
  ];

  static const List<Map<String, dynamic>> _teamMembers = [
    {
      'name': 'Jaxon Topel',
      'role': 'Embedded Code Development',
      'details': [
        'Node → Gadget Communication',
        'Image Processing Algorithm Development & Testing',
        'System Architecture Design',
      ],
      'image': 'assets/images/jaxon.png',
    },
    {
      'name': 'Phillip Murano',
      'role': 'CAD & Power Management',
      'details': [
        'CAD Development',
        'Node: Alarm system / LEDs',
        'Power Management',
      ],
      'image': 'assets/images/phillip.png',
    },
    {
      'name': 'Dylan Myers',
      'role': 'PCB & Hardware Integration',
      'details': [
        'PCB Design',
        'Gadget Peripherals',
        'Node: Camera / IR Sensors',
      ],
      'image': 'assets/images/dylan.png',
    },
    {
      'name': 'Colin Kirby',
      'role': 'Mobile & Web Development',
      'details': [
        'Mobile App Development',
        'Gadget → App Communication',
        'Website Development',
      ],
      'image': 'assets/images/colin.png',
    },
  ];

  static const String _contactEmail = 'co201115@ucf.edu';
  static const String _contactWebsite = 'www.securescape.com';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return GestureDetector(
      onPanUpdate: _updateParallaxOffset,
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Animated App Bar with Parallax
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.deepForestGreen,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'About SecureScape',
                  style: TextStyle(
                    color: _scrollOffset > 130 ? Colors.white : Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Animated Background
                    AnimatedBuilder(
                      animation: _parallaxController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _parallaxOffset,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.deepForestGreen,
                                  AppTheme.pineGreen,
                                  AppTheme.mistGray,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Glowing Logo
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.pineGreen.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/dssLogo.png',
                            height: 100,
                          ),
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 400.ms)
                      .move(begin: const Offset(-20, 0), end: Offset.zero),
                  ],
                ),
              ),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(isLargeScreen ? 32.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About Section with Animation
                    _buildAnimatedSection(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, 'About SecureScape'),
                          const SizedBox(height: 8),
                          _buildBodyText(context, _aboutText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mission Section with Animation
                    _buildAnimatedSection(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, 'Our Mission'),
                          const SizedBox(height: 8),
                          _buildBodyText(context, _missionText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Features Section with Animated Icons
                    _buildSectionHeader(context, 'Key Features')
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideX(begin: -0.2),
                    const SizedBox(height: 16),
                    ..._features.asMap().entries.map((entry) {
                      return _buildAnimatedFeatureItem(
                        context,
                        entry.value,
                        delay: 600 + (entry.key * 200),
                      );
                    }).toList(),
                    const SizedBox(height: 32),

                    // Team Section with Flip Cards
                    _buildSectionHeader(context, 'Meet the Team')
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .slideX(begin: -0.2),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLargeScreen ? 2 : 1,
                        childAspectRatio: isLargeScreen ? 1.6 : 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _teamMembers.length,
                      itemBuilder: (context, index) => _buildAnimatedTeamMember(
                        context,
                        _teamMembers[index],
                        isLargeScreen,
                        delay: 1000 + (index * 200),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _launchUrl('mailto:$_contactEmail'),
          label: const Text('Contact Us'),
          icon: const Icon(Icons.email),
          backgroundColor: AppTheme.pineGreen,
        ).animate()
          .fadeIn(delay: 1500.ms)
          .slideY(begin: 1, end: 0),
      ),
    );
  }

  Widget _buildAnimatedFeatureItem(
    BuildContext context,
    Map<String, String> feature,
    {required int delay}
  ) {
    IconData iconData = _getIconData(feature['icon'] ?? '');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: AppTheme.pineGreen, size: 28)
            .animate()
            .fadeIn(delay: Duration(milliseconds: delay))
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1000.ms, delay: 2000.ms),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.deepForestGreen.withOpacity(0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: Duration(milliseconds: delay + 200))
            .slideX(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildAnimatedTeamMember(
    BuildContext context,
    Map<String, dynamic> member,
    bool isLargeScreen,
    {required int delay}
  ) {
    final isExpanded = _expandedTeamMembers[member['name'] as String] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedTeamMembers[member['name'] as String] = !isExpanded;
        });
      },
      child: Card(
        elevation: isExpanded ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'team_${member['name']}',
                      child: CircleAvatar(
                        radius: isLargeScreen ? 40 : 36,
                        backgroundColor: AppTheme.pineGreen.withOpacity(0.1),
                        backgroundImage: AssetImage(member['image']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepForestGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member['role'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.pineGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.pineGreen,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.pineGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responsibilities:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepForestGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List<Widget>.from(
                          (member['details'] as List<dynamic>).map(
                            (detail) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppTheme.pineGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      detail,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.deepForestGreen.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn()
                    .moveY(begin: 20, end: 0),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: delay))
      .moveY(begin: 20, end: 0);
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'motion_photos_on':
        return Icons.motion_photos_on;
      case 'notifications_active':
        return Icons.notifications_active;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'battery_std':
        return Icons.battery_std;
      default:
        return Icons.star;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.deepForestGreen,
          ),
    );
  }

  Widget _buildBodyText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: AppTheme.deepForestGreen.withOpacity(0.85),
          ),
    );
  }
}
