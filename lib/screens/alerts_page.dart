import 'package:flutter/material.dart';
import '../widgets/security_card.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecurityCard(
            title: 'Recent Alerts',
            child: Column(
              children: List.generate(
                5,
                (index) => _buildAlertTile(
                  title: _getAlertTitle(index),
                  subtitle: _getAlertSubtitle(index),
                  icon: _getAlertIcon(index),
                  time: DateTime.now().subtract(Duration(hours: index)),
                  severity: _getAlertSeverity(index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'Alert Statistics',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatistic('Today', '5'),
                  _buildStatistic('This Week', '23'),
                  _buildStatistic('This Month', '64'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required DateTime time,
    required Color severity,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: severity.withOpacity(0.1),
        child: Icon(icon, color: severity),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${time.day}/${time.month}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to alert detail
      },
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getAlertTitle(int index) {
    final titles = [
      'Motion Detected',
      'Camera Offline',
      'Battery Low',
      'Tampering Detected',
      'System Armed',
    ];
    return titles[index % titles.length];
  }

  String _getAlertSubtitle(int index) {
    final subtitles = [
      'Movement detected on Camera 1',
      'Camera 2 lost connection',
      'Camera 3 battery at 10%',
      'Possible tampering on Camera 4',
      'System armed by admin',
    ];
    return subtitles[index % subtitles.length];
  }

  IconData _getAlertIcon(int index) {
    final icons = [
      Icons.motion_photos_on,
      Icons.wifi_off,
      Icons.battery_alert,
      Icons.warning,
      Icons.security,
    ];
    return icons[index % icons.length];
  }

  Color _getAlertSeverity(int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.red,
      Colors.green,
    ];
    return colors[index % colors.length];
  }

  static void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Motion Detection'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('System Events'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Camera Status'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
} 