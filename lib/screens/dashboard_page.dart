import 'package:flutter/material.dart';
import '../widgets/connection_status.dart';
import '../widgets/security_card.dart';
import '../widgets/dev_menu.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('SecureScape'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.pineGreen),
            onPressed: () {
              // TODO: Implement refresh
            },
          ),
          const DevMenu(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ConnectionStatus(),
          const SizedBox(height: 24),
          SecurityCard(
            title: 'System Status',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.pineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'System Armed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepForestGreen,
                      ),
                    ),
                    subtitle: Text(
                      'Tap to arm/disarm the system',
                      style: TextStyle(
                        color: AppTheme.deepForestGreen.withOpacity(0.7),
                      ),
                    ),
                    value: true, // TODO: Connect to provider
                    activeColor: AppTheme.pineGreen,
                    onChanged: (value) {
                      // TODO: Implement arming logic
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security, color: AppTheme.pineGreen),
                    title: Text(
                      'All Nodes Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepForestGreen,
                      ),
                    ),
                    subtitle: Text(
                      '6 nodes connected',
                      style: TextStyle(
                        color: AppTheme.deepForestGreen.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecurityCard(
                  title: 'Quick Actions',
                  child: Column(
                    children: [
                      _QuickActionButton(
                        icon: Icons.alarm,
                        label: 'Trigger Alarm',
                        onPressed: () {
                          // TODO: Implement alarm trigger
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickActionButton(
                        icon: Icons.camera_alt,
                        label: 'Take Photos',
                        onPressed: () {
                          Navigator.pushNamed(context, '/photos');
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickActionButton(
                        icon: Icons.history,
                        label: 'View Logs',
                        onPressed: () {
                          Navigator.pushNamed(context, '/logs');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'Recent Activity',
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.pineGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.pineGreen.withOpacity(0.2),
                      child: Icon(
                        Icons.notification_important,
                        color: AppTheme.pineGreen,
                      ),
                    ),
                    title: Text(
                      'Motion Detected - Node ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepForestGreen,
                      ),
                    ),
                    subtitle: Text(
                      '${DateTime.now().subtract(
                        Duration(minutes: index * 5),
                      ).toString().split('.')[0]}',
                      style: TextStyle(
                        color: AppTheme.deepForestGreen.withOpacity(0.7),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppTheme.pineGreen,
                    ),
                    onTap: () {
                      // TODO: Navigate to detail view
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: AppTheme.pineGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
} 