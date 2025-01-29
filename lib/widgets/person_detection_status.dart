import 'package:flutter/material.dart';
import '../services/person_detection_service.dart';

class PersonDetectionStatus extends StatefulWidget {
  const PersonDetectionStatus({Key? key}) : super(key: key);

  @override
  State<PersonDetectionStatus> createState() => _PersonDetectionStatusState();
}

class _PersonDetectionStatusState extends State<PersonDetectionStatus> {
  final _personDetectionService = PersonDetectionService();

  @override
  void initState() {
    super.initState();
    _personDetectionService.startPolling();
  }

  @override
  void dispose() {
    _personDetectionService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _personDetectionService.personDetectionStream,
      builder: (context, snapshot) {
        final isPersonDetected = snapshot.data ?? false;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Person Detection Status:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPersonDetected ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPersonDetected ? 'Person Detected!' : 'No Person Detected',
                  style: TextStyle(
                    color: isPersonDetected ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final success = await _personDetectionService.triggerPersonDetection();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to trigger person detection'),
                        ),
                      );
                    }
                  },
                  child: const Text('Test Detection'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 