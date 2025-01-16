import 'package:flutter/material.dart';
import '../widgets/security_card.dart';

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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecurityCard(
            title: 'Notification Settings',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts on your device'),
                  value: _notificationsEnabled,
                  onChanged: (value) => setState(() => _notificationsEnabled = value),
                ),
                SwitchListTile(
                  title: const Text('Sound Alerts'),
                  subtitle: const Text('Play sound for important alerts'),
                  value: _soundEnabled,
                  onChanged: (value) => setState(() => _soundEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'System Settings',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-Arm System'),
                  subtitle: const Text('Automatically arm at scheduled times'),
                  value: _autoArm,
                  onChanged: (value) => setState(() => _autoArm = value),
                ),
                ListTile(
                  title: const Text('Camera Settings'),
                  subtitle: const Text('Configure resolution and refresh rate'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCameraSettings(context),
                ),
                ListTile(
                  title: const Text('Network Settings'),
                  subtitle: const Text('Configure WiFi and connection settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNetworkSettings(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'Account',
            child: Column(
              children: [
                ListTile(
                  title: const Text('Device Information'),
                  subtitle: const Text('View system details and status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDeviceInfo(context),
                ),
                ListTile(
                  title: const Text('About'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _resetSystem(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset System'),
          ),
        ],
      ),
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
      applicationIcon: const FlutterLogo(size: 64),
      children: const [
        Text('A modern security system for your home.'),
      ],
    );
  }

  void _resetSystem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset System'),
        content: const Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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