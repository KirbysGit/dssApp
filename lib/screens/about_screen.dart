import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.pineGreen, size: 32),
            const SizedBox(width: 12),
            const Text('About SecureScape'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // App Logo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Image.asset('assets/images/dssLogo.png', height: 100),
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.deepForestGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SecureScape is an innovative security solution designed to protect your home and property. '
                  'Our system combines advanced camera technology with real-time monitoring to provide comprehensive security coverage.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Features',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  Icons.camera_alt,
                  'Real-time Camera Feeds',
                  'Monitor your property in real-time with high-quality video feeds',
                ),
                _buildFeatureItem(
                  context,
                  Icons.motion_photos_on,
                  'Motion Detection',
                  'Instant alerts when movement is detected in monitored areas',
                ),
                _buildFeatureItem(
                  context,
                  Icons.notifications_active,
                  'Smart Notifications',
                  'Customizable alerts and notifications for various security events',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Team Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Development Team',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTeamMember(
                  context,
                  'Jaxon Topel',
                  'Lead Developer',
                  'Responsible for system architecture and implementation',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Us',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  context,
                  Icons.email,
                  'Email',
                  'support@securescape.com',
                ),
                _buildContactItem(
                  context,
                  Icons.web,
                  'Website',
                  'www.securescape.com',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Copyright
          Center(
            child: Text(
              '© 2024 SecureScape. All rights reserved.',
              style: TextStyle(color: AppTheme.deepForestGreen.withOpacity(0.6)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.pineGreen,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.deepForestGreen.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(
    BuildContext context,
    String name,
    String role,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pineGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.deepForestGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              color: AppTheme.pineGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.deepForestGreen.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.pineGreen,
            size: 24,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.deepForestGreen,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.deepForestGreen.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 