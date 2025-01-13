class CameraNode {
  final String id;
  final String ipAddress;
  final bool isActive;
  final DateTime lastUpdate;
  final String status;

  CameraNode({
    required this.id,
    required this.ipAddress,
    this.isActive = true,
    required this.lastUpdate,
    this.status = 'Online',
  });

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