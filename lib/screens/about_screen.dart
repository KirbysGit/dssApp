import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

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

  static const List<Map<String, String>> _teamMembers = [
    {
      'name': 'Jaxon Topel',
      'role': 'Image Processing & Software Development',
    },
    {
      'name': 'Colin Kirby',
      'role': 'Embedded Systems & Mobile App Development',
    },
    {
      'name': 'Dylan Myers',
      'role': 'PCB & Hardware Integration',
    },
    {
      'name': 'Phillip Murano',
      'role': 'PCB & Embedded Code Development',
    },
  ];

  static const String _contactEmail = 'support@securescape.com';
  static const String _contactWebsite = 'www.securescape.com';

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
          // Header: Logo and Version
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
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
          ),
          
          // About Section
          _buildSectionHeader(context, 'About SecureScape'),
          const SizedBox(height: 8),
          _buildBodyText(context, _aboutText),
          const SizedBox(height: 24),

          // Mission Section
          _buildSectionHeader(context, 'Our Mission'),
          const SizedBox(height: 8),
          _buildBodyText(context, _missionText),
          const SizedBox(height: 24),

          // Features Section
          _buildSectionHeader(context, 'Key Features'),
          const SizedBox(height: 8),
          ..._features.map((feature) => _buildFeatureItem(context, feature)).toList(),
          const SizedBox(height: 24),

          // Meet the Team Section
          _buildSectionHeader(context, 'Meet the Team'),
          const SizedBox(height: 8),
          ..._teamMembers.map((member) => _buildTeamMember(context, member)).toList(),
          const SizedBox(height: 24),

          // About SecureScape Purpose
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'SecureScape is designed to give you control, security, and awareness—even in the most unpredictable environments.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.deepForestGreen,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Contact Section
          _buildSectionHeader(context, 'Contact Us'),
          const SizedBox(height: 8),
          _buildContactItem(context, Icons.email, 'Email', _contactEmail),
          _buildContactItem(context, Icons.web, 'Website', _contactWebsite),
          const SizedBox(height: 24),

          // Copyright
          Center(
            child: Text(
              '© 2024 SecureScape. All rights reserved.',
              style: TextStyle(color: AppTheme.deepForestGreen.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildFeatureItem(BuildContext context, Map<String, String> feature) {
    // Map the icon string to an actual icon (you can improve this mapping as needed)
    IconData iconData;
    switch (feature['icon']) {
      case 'motion_photos_on':
        iconData = Icons.motion_photos_on;
        break;
      case 'notifications_active':
        iconData = Icons.notifications_active;
        break;
      case 'camera_alt':
        iconData = Icons.camera_alt;
        break;
      case 'battery_std':
        iconData = Icons.battery_std;
        break;
      default:
        iconData = Icons.star;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: AppTheme.pineGreen, size: 28),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(BuildContext context, Map<String, String> member) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.pineGreen.withOpacity(0.1),
          child: Text(
            member['name']?.substring(0, 1) ?? '',
            style: TextStyle(
              color: AppTheme.deepForestGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member['name'] ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepForestGreen,
              ),
        ),
        subtitle: Text(
          member['role'] ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.pineGreen,
              ),
        ),
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.pineGreen, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepForestGreen,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.deepForestGreen.withOpacity(0.75),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
