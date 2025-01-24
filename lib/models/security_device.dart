class SecurityDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String ipAddress;
  bool isOnline;
  bool isMotionDetected;
  DateTime? lastMotionDetected;
  
  SecurityDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    required this.isOnline,
    this.isMotionDetected = false,
    this.lastMotionDetected,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'ipAddress': ipAddress,
    'isOnline': isOnline,
    'isMotionDetected': isMotionDetected,
    'lastMotionDetected': lastMotionDetected?.toIso8601String(),
  };
  
  factory SecurityDevice.fromJson(Map<String, dynamic> json) => SecurityDevice(
    id: json['id'],
    name: json['name'],
    type: DeviceType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
      orElse: () => DeviceType.camera,
    ),
    ipAddress: json['ipAddress'],
    isOnline: json['isOnline'] ?? false,
    isMotionDetected: json['isMotionDetected'] ?? false,
    lastMotionDetected: json['lastMotionDetected'] != null 
      ? DateTime.parse(json['lastMotionDetected'])
      : null,
  );
}

enum DeviceType {
  camera,
  motionSensor,
  doorLock,
}