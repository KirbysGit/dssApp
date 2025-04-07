import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AlertScreen extends StatelessWidget {
  final Uint8List? image;
  final String cameraName;
  final DateTime timestamp;

  const AlertScreen({
    Key? key,
    required this.image,
    required this.cameraName,
    required this.timestamp,
  }) : super(key: key);

  String _formatCameraName(String name) {
    return name.replaceAll('camera_node', 'Node ');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy, hh:mm:ss a');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section
                  if (image != null)
                    Hero(
                      tag: 'alert_image',
                      child: Image.memory(
                        image!,
                        fit: BoxFit.contain,
                        height: MediaQuery.of(context).size.height * 0.6,
                      ),
                    )
                  else
                    Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
                    ),

                  // Info section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.deepForestGreen,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Alert header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Person Detected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Detection details
                        _buildInfoRow(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          value: '${_formatCameraName(cameraName)} Camera',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: dateFormatter.format(timestamp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SF Pro Text',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 