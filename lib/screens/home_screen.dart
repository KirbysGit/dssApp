import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/security_card.dart';
import '../widgets/camera_feed.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/dssLogo.png', height: 40),
            const SizedBox(width: 12),
            const Text('SecureScape'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Camera Feed Section
              Container(
                height: 300,
                decoration: AppTheme.cardDecoration,
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: CameraFeed(
                    ipAddress: '192.168.1.100', // TODO: Get IP from settings or state management
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    'Trigger Alarm',
                    Icons.notification_important,
                    AppTheme.pineGreen,
                    () {
                      // Trigger alarm action
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Turn Off Alarm',
                    Icons.notifications_off,
                    AppTheme.mossGreen,
                    () {
                      // Turn off alarm action
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Toggle Lights',
                    Icons.lightbulb_outline,
                    AppTheme.accentGold,
                    () {
                      // Toggle lights action
                    },
                  ),
                  _buildActionCard(
                    context,
                    'System Status',
                    Icons.security,
                    AppTheme.deepForestGreen,
                    () {
                      // Show system status
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.mossGreen,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                      title: Text('Motion Detected'),
                      subtitle: Text('2 minutes ago'),
                      trailing: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          // View details
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Capture image action
        },
        backgroundColor: AppTheme.pineGreen,
        label: const Text('Capture'),
        icon: const Icon(Icons.camera),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 