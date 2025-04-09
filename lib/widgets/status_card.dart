import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/security_state.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class StatusCard extends ConsumerWidget {
  final SecurityState status;
  final DateFormat dateFormatter;
  final String? activeCameraName;
  final bool isLargeScreen;

  const StatusCard({
    Key? key,
    required this.status,
    required this.dateFormatter,
    required this.activeCameraName,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusText(),
                          if (status.lastDetectionTime != null) ...[
                            const SizedBox(height: 4),
                            _buildTimestamp(),
                          ],
                          if (activeCameraName != null) ...[
                            const SizedBox(height: 4),
                            _buildCameraInfo(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (status.personDetected ? Colors.red : Colors.green).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              status.personDetected ? Icons.warning : Icons.check_circle,
              color: status.personDetected ? Colors.red : Colors.green,
              size: isLargeScreen ? 48 : 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return Text(
      status.personDetected ? 'Person Detected!' : 'All Clear',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: isLargeScreen ? 24 : 20,
        fontFamily: 'SF Pro Display',
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      'Last Detection: ${dateFormatter.format(status.lastDetectionTime!)}',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: isLargeScreen ? 16 : 14,
        fontFamily: 'SF Pro Text',
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCameraInfo() {
    return Text(
      'Camera: ${activeCameraName?.replaceAll('camera_node', 'Node ') ?? 'Unknown'} Camera',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: isLargeScreen ? 14 : 12,
        fontFamily: 'SF Pro Text',
        letterSpacing: 0.3,
      ),
    );
  }
} 