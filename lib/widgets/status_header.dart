import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../services/person_detection_service.dart';
import '../theme/app_theme.dart';

class StatusHeader extends StatefulWidget {
  const StatusHeader({super.key});

  @override
  State<StatusHeader> createState() => _StatusHeaderState();
}

class _StatusHeaderState extends State<StatusHeader> {
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
    return Consumer<SecurityProvider>(
      builder: (context, provider, child) {
        final onlineDevices = provider.devices.where((d) => d.isOnline).length;
        final totalDevices = provider.devices.length;

        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    onlineDevices == totalDevices
                        ? Icons.check_circle
                        : Icons.warning,
                    color: onlineDevices == totalDevices
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$onlineDevices/$totalDevices devices online',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Person Detection Status
              StreamBuilder<bool>(
                stream: _personDetectionService.personDetectionStream,
                builder: (context, snapshot) {
                  final isPersonDetected = snapshot.data ?? false;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPersonDetected ? Icons.warning : Icons.person_off,
                                color: isPersonDetected ? Colors.red : Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Person Detection',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () {
                              _personDetectionService.checkPersonDetectionStatus();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Refreshing person detection status...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            color: AppTheme.pineGreen,
                          ),
                        ],
                      ),
                      if (isPersonDetected)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Person Detected!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}