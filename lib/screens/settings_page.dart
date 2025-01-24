import 'package:flutter/material.dart';
import '../widgets/security_card.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _autoArm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.pineGreen, size: 32),
            const SizedBox(width: 12),
            const Text('Settings'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecurityCard(
            title: 'Notification Settings',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.pineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive alerts on your device',
                    _notificationsEnabled,
                    (value) => setState(() => _notificationsEnabled = value),
                  ),
                  _buildSwitchTile(
                    'Sound Alerts',
                    'Play sound for important alerts',
                    _soundEnabled,
                    (value) => setState(() => _soundEnabled = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'System Settings',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.pineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Auto-Arm System',
                    'Automatically arm at scheduled times',
                    _autoArm,
                    (value) => setState(() => _autoArm = value),
                  ),
                  _buildNavigationTile(
                    'Camera Settings',
                    'Configure resolution and refresh rate',
                    Icons.camera_alt,
                    () => _showCameraSettings(context),
                  ),
                  _buildNavigationTile(
                    'Network Settings',
                    'Configure WiFi and connection settings',
                    Icons.wifi,
                    () => _showNetworkSettings(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'Account',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.pineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Device Information',
                    'View system details and status',
                    Icons.info,
                    () => _showDeviceInfo(context),
                  ),
                  _buildNavigationTile(
                    'About',
                    'Version 1.0.0',
                    Icons.help,
                    () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _resetSystem(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.warning),
            label: const Text('Reset System'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.deepForestGreen,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.deepForestGreen.withOpacity(0.7),
        ),
      ),
      value: value,
      activeColor: AppTheme.pineGreen,
      onChanged: onChanged,
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.pineGreen),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.deepForestGreen,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.deepForestGreen.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.pineGreen,
      ),
      onTap: onTap,
    );
  }

  void _showCameraSettings(BuildContext context) {
    // TODO: Implement camera settings dialog
  }

  void _showNetworkSettings(BuildContext context) {
    // TODO: Implement network settings dialog
  }

  void _showDeviceInfo(BuildContext context) {
    // TODO: Implement device info dialog
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SecureScape',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/images/logo.png', height: 64),
      children: [
        Text(
          'A modern security system for your home.',
          style: TextStyle(color: AppTheme.deepForestGreen),
        ),
      ],
    );
  }

  void _resetSystem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset System',
          style: TextStyle(
            color: AppTheme.deepForestGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.',
          style: TextStyle(color: AppTheme.deepForestGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.deepForestGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement system reset
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 