import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/security_provider.dart';
import '../models/detection_log.dart';
import '../screens/dashboard_screen.dart';
import '../screens/cameras_screen.dart';
import '../screens/alert_screen.dart';

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
    
    // Add scroll listener for infinite scrolling
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
    // For now, just refresh the logs since we're handling real-time updates
    await ref.read(detectionLogsProvider.notifier).loadInitialLogs();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshLogs() async {
    await _loadInitialLogs();
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Detection History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement filtering
                      },
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshLogs,
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            'No detection logs yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 24.0 : 16.0,
                            vertical: 16.0,
                          ),
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
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
          selectedIndex: 0, // Logs tab is selected
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.history, color: Colors.white),
              label: 'Logs',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.home, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.camera_alt, color: Colors.white),
              label: 'Cameras',
            ),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                // Already on logs
                break;
              case 1:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
                break;
              case 2:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CamerasScreen(),
                  ),
                );
                break;
            }
          },
        ),
      ),
    );
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