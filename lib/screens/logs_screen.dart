import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/security_provider.dart';
import '../models/detection_log.dart';
import '../screens/dashboard_screen.dart';
import '../screens/cameras_screen.dart';
import '../screens/alert_screen.dart';
import '../screens/test_gadget_screen.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy, hh:mm a');
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreLogs();
      }
    });
  }

  Future<void> _loadInitialLogs() async {
    setState(() => _isLoading = true);
    await ref.read(detectionLogsProvider.notifier).loadInitialLogs();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await ref.read(detectionLogsProvider.notifier).loadInitialLogs();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshLogs() async {
    await _loadInitialLogs();
  }

  void _clearAllLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to clear all detection logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(detectionLogsProvider.notifier).clearLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All logs cleared'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final logs = ref.watch(detectionLogsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepForestGreen.withOpacity(0.95),
              AppTheme.pineGreen.withOpacity(0.85),
              AppTheme.mistGray.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isLargeScreen),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshLogs,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24.0 : 16.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Recent Detections'),
                        const SizedBox(height: 16),
                        logs.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: logs.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == logs.length) {
                                    return _isLoading
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink();
                                  }

                                  final log = logs[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: LogEntryCard(
                                      log: log,
                                      dateFormatter: _dateFormatter,
                                      isLargeScreen: isLargeScreen,
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
      floatingActionButton: logs.isNotEmpty
          ? FloatingActionButton(
              onPressed: _clearAllLogs,
              backgroundColor: Colors.red.withOpacity(0.8),
              child: const Icon(Icons.delete_outline),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLargeScreen ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              Text(
                'View detection history and alerts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshLogs,
              tooltip: 'Refresh Logs',
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Display',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Detection Logs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detection events will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshLogs,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepForestGreen.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.deepForestGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 65,
        selectedIndex: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _buildNavDestination(Icons.history_outlined, Icons.history, 'Logs'),
          _buildNavDestination(Icons.home_outlined, Icons.home, 'Home'),
          _buildNavDestination(Icons.camera_alt_outlined, Icons.camera_alt, 'Cameras'),
          _buildNavDestination(Icons.build_outlined, Icons.build, 'Utility'),
        ],
        onDestinationSelected: (index) => _handleNavigation(context, index),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(outlinedIcon, color: Colors.white.withOpacity(0.7)),
      selectedIcon: Icon(filledIcon, color: Colors.white),
      label: label,
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final routes = [
      const LogsScreen(),
      const DashboardScreen(),
      const CamerasScreen(),
      const TestGadgetScreen(),
    ];

    if (index != 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => routes[index],
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class LogEntryCard extends StatelessWidget {
  final DetectionLog log;
  final DateFormat dateFormatter;
  final bool isLargeScreen;

  const LogEntryCard({
    Key? key,
    required this.log,
    required this.dateFormatter,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show AlertScreen when tapped
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => AlertScreen(
                  image: log.imageBytes,
                  cameraName: log.cameraName,
                  timestamp: log.timestamp,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: log.imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            log.imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white54,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Person Detected',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (log.wasAlarmTriggered) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_active,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Alarm',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SF Pro Text',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Camera: ${log.cameraName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormatter.format(log.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isLargeScreen ? 14 : 12,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 