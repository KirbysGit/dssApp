import 'package:flutter/material.dart';
import '../widgets/connection_status.dart';
import '../widgets/security_card.dart';
import '../widgets/dev_menu.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureScape'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('System Armed'),
                  subtitle: const Text('Tap to arm/disarm the system'),
                  value: true, // TODO: Connect to provider
                  onChanged: (value) {
                    // TODO: Implement arming logic
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.security),
                  title: Text('All Nodes Active'),
                  subtitle: Text('6 nodes connected'),
                ),
              ],
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
                (index) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.notification_important),
                  ),
                  title: Text('Motion Detected - Node ${index + 1}'),
                  subtitle: Text('${DateTime.now().subtract(
                    Duration(minutes: index * 5),
                  ).toString().split('.')[0]}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to detail view
                  },
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
        ),
      ),
    );
  }
} 