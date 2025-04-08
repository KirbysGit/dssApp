// lib/models/camera_node.dart

// CameraNode model
class CameraNode {
  final String id;            // Unique Identifier For Camera Node.
  final String ipAddress;     // IP Address Of Camera Node.
  final bool isActive;        // Whether The Node Is Currently Active.
  final DateTime lastUpdate;  // Timestamp Of The Last Update.
  final String status;        // Status Of The Node (e.g., "Online", "Offline")

  // Constructor For CameraNode.
  CameraNode({
    required this.id, 
    required this.ipAddress,
    this.isActive = true,
    required this.lastUpdate,
    this.status = 'Online',
  });

  // Create CameraNode From JSON.
  factory CameraNode.fromJson(Map<String, dynamic> json) {
    return CameraNode(
      id: json['id'],   
      ipAddress: json['ip_address'],
      isActive: json['is_active'] ?? true,
      lastUpdate: DateTime.parse(json['last_update']),
      status: json['status'] ?? 'Online',
    );
  }
} 