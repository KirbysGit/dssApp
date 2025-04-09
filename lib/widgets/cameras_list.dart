import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/security_state.dart';
import 'dart:ui';

class CamerasList extends StatelessWidget {
  final List<Map<String, dynamic>> cameras;
  final DateFormat dateFormatter;
  final Function(Map<String, dynamic>) onRefresh;
  final bool isLargeScreen;

  const CamerasList({
    Key? key,
    required this.cameras,
    required this.dateFormatter,
    required this.onRefresh,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cameras.length,
        itemBuilder: (context, index) {
          final camera = cameras[index];
          final lastSeen = DateTime.fromMillisecondsSinceEpoch(
            camera['lastSeen'] ?? 0,
          );
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CameraCard(
              camera: camera,
              lastSeen: lastSeen,
              dateFormatter: dateFormatter,
              onRefresh: onRefresh,
              isLargeScreen: isLargeScreen,
            ),
          );
        },
      ),
    );
  }
}

class CameraCard extends StatelessWidget {
  final Map<String, dynamic> camera;
  final DateTime lastSeen;
  final DateFormat dateFormatter;
  final Function(Map<String, dynamic>) onRefresh;
  final bool isLargeScreen;

  const CameraCard({
    Key? key,
    required this.camera,
    required this.lastSeen,
    required this.dateFormatter,
    required this.onRefresh,
    required this.isLargeScreen,
  }) : super(key: key);

  String _getFormattedTimestamp() {
    final now = DateTime.now();
    if (lastSeen.year < 2020 || lastSeen.isAfter(now)) {
      return 'Last seen: Just now';
    }

    final difference = now.difference(lastSeen);
    if (difference.inSeconds < 60) {
      return 'Last seen: Just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen: ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen: ${difference.inHours}h ago';
    } else {
      return 'Last seen: ${dateFormatter.format(lastSeen)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onRefresh(camera),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.pineGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: isLargeScreen ? 28 : 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      camera['name'] ?? 'Unknown Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isLargeScreen ? 14 : 12,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedTimestamp(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isLargeScreen ? 12 : 10,
                        fontFamily: 'SF Pro Text',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetectionCard extends StatelessWidget {
  final Image image;
  final SecurityState status;
  final DateFormat dateFormatter;
  final String? activeCameraName;
  final VoidCallback onFullScreen;
  final bool isLargeScreen;

  const DetectionCard({
    Key? key,
    required this.image,
    required this.status,
    required this.dateFormatter,
    required this.activeCameraName,
    required this.onFullScreen,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeCameraName != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.pineGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeCameraName?.replaceAll('camera_node', 'Node ') ?? 'Unknown'} Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ),
              Hero(
                tag: 'detection_image',
                child: GestureDetector(
                  onTap: onFullScreen,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: image,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (status.lastDetectionTime != null)
                      Expanded(
                        child: Text(
                          dateFormatter.format(status.lastDetectionTime!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isLargeScreen ? 14 : 12,
                            fontFamily: 'SF Pro Text',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: isLargeScreen ? 28 : 24,
                      ),
                      onPressed: onFullScreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
