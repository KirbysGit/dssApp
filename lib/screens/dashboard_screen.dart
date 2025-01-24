import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../widgets/device_grid.dart';
import '../widgets/status_header.dart';
import '../widgets/alert_list.dart';
import '../screens/camera_screen.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Refresh devices when screen loads
    Future.microtask(() =>
        Provider.of<SecurityProvider>(context, listen: false).refreshDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.pineGreen, size: 32),
            const SizedBox(width: 12),
            const Text('Security Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.pineGreen),
            onPressed: () {
              // TODO: Implement add device dialog
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppTheme.pineGreen),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<SecurityProvider>(context, listen: false)
              .refreshDevices();
        },
        color: AppTheme.pineGreen,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: StatusHeader(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Devices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepForestGreen,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to devices screen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.pineGreen,
                      ),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: DeviceGrid(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepForestGreen,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: AlertList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.pineGreen.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard,
              color: _selectedIndex == 0
                  ? AppTheme.pineGreen
                  : AppTheme.deepForestGreen.withOpacity(0.7),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.videocam,
              color: _selectedIndex == 1
                  ? AppTheme.pineGreen
                  : AppTheme.deepForestGreen.withOpacity(0.7),
            ),
            label: 'Cameras',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.notifications,
              color: _selectedIndex == 2
                  ? AppTheme.pineGreen
                  : AppTheme.deepForestGreen.withOpacity(0.7),
            ),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.pineGreen,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}