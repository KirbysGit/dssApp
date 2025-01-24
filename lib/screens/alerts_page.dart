import 'package:flutter/material.dart';
import '../widgets/security_card.dart';
import '../theme/app_theme.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.pineGreen, size: 32),
            const SizedBox(width: 12),
            const Text('Alerts & Notifications'),
          ],
        ),
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
                  context: context,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'Alert Statistics',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: AppTheme.pineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatistic(context, 'Today', '5'),
                  _buildStatistic(context, 'This Week', '23'),
                  _buildStatistic(context, 'This Month', '64'),
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
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: severity.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severity.withOpacity(0.2),
          child: Icon(icon, color: severity),
        ),
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.deepForestGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${time.day}/${time.month}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.deepForestGreen.withOpacity(0.7),
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to alert detail
        },
      ),
    );
  }

  Widget _buildStatistic(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepForestGreen,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.deepForestGreen.withOpacity(0.7),
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
      AppTheme.pineGreen,
      AppTheme.accentGold,
      AppTheme.accentGold,
      AppTheme.deepForestGreen,
      AppTheme.mossGreen,
    ];
    return colors[index % colors.length];
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Alerts',
          style: TextStyle(
            color: AppTheme.deepForestGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(context, 'Motion Detection'),
            _buildFilterOption(context, 'System Events'),
            _buildFilterOption(context, 'Camera Status'),
          ],
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pineGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String title) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(color: AppTheme.deepForestGreen),
      ),
      value: true,
      activeColor: AppTheme.pineGreen,
      onChanged: (value) {},
    );
  }
} 