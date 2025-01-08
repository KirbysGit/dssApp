class SecurityDevice {
  final String id;
  final String name;
  final String ipAddress;
  bool isOnline;
  bool isMotionDetected;
  DateTime? lastMotionDetected;
  
  SecurityDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.isOnline = false,
    this.isMotionDetected = false,
    this.lastMotionDetected,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ipAddress': ipAddress,
    'isOnline': isOnline,
    'isMotionDetected': isMotionDetected,
    'lastMotionDetected': lastMotionDetected?.toIso8601String(),
  };
  
  factory SecurityDevice.fromJson(Map<String, dynamic> json) => SecurityDevice(
    id: json['id'],
    name: json['name'],
    ipAddress: json['ipAddress'],
    isOnline: json['isOnline'] ?? false,
    isMotionDetected: json['isMotionDetected'] ?? false,
    lastMotionDetected: json['lastMotionDetected'] != null 
      ? DateTime.parse(json['lastMotionDetected'])
      : null,
  );
}