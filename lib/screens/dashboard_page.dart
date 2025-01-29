import 'package:flutter/material.dart';
import '../widgets/security_card.dart';
import '../theme/app_theme.dart';
import '../services/person_detection_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _personDetectionService = PersonDetectionService();

  @override
  void initState() {
    super.initState();
    _personDetectionService.startPolling();
  }

  @override
  void dispose() {
    _personDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: const Text('Person Detection Test'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.pineGreen),
            onPressed: () {
              _personDetectionService.checkPersonDetectionStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing status...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Info Card
          SecurityCard(
            title: 'Connection Info',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.pineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESP32 IP: 172.20.10.8',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepForestGreen,
                    ),
                  ),
                  Text(
                    'Endpoint: /person-status',
                    style: TextStyle(
                      color: AppTheme.deepForestGreen.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Person Detection Status Card
          SecurityCard(
            title: 'Person Detection Status',
            child: StreamBuilder<bool>(
              stream: _personDetectionService.personDetectionStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final isPersonDetected = snapshot.data ?? false;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPersonDetected 
                      ? Colors.red.withOpacity(0.1) 
                      : AppTheme.pineGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPersonDetected ? Icons.warning : Icons.check_circle,
                            color: isPersonDetected ? Colors.red : AppTheme.pineGreen,
                            size: 48,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPersonDetected ? 'Person Detected!' : 'No Person Detected',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isPersonDetected ? Colors.red : AppTheme.deepForestGreen,
                                  ),
                                ),
                                Text(
                                  'Last updated: ${DateTime.now().toString().split('.')[0]}',
                                  style: TextStyle(
                                    color: AppTheme.deepForestGreen.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Status'),
                            onPressed: () => _personDetectionService.checkPersonDetectionStatus(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pineGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.warning),
                            label: const Text('Test Detection'),
                            onPressed: () async {
                              final success = await _personDetectionService.triggerPersonDetection();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success ? 'Test detection triggered' : 'Failed to trigger detection'
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.deepForestGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            error,
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Connection'),
            onPressed: () => _personDetectionService.checkPersonDetectionStatus(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pineGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 