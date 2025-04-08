// lib/models/security_device.dart

class SecurityDevice {
  final String id;              // Unique Identifier For Security Device.
  final String name;            // Name Of The Security Device.
  final DeviceType type;        // Type Of The Security Device.
  final String ipAddress;       // IP Address Of The Security Device.
  bool isOnline;                // Whether The Device Is Online.
  bool isMotionDetected;        // Whether The Motion Sensor Is Detected.
  DateTime? lastMotionDetected; // Last Motion Detected Timestamp.
  
  // Constructor For SecurityDevice.
  SecurityDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    required this.isOnline,
    this.isMotionDetected = false,
    this.lastMotionDetected,
  });
  
  // Convert SecurityDevice To JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'ipAddress': ipAddress,
    'isOnline': isOnline,
    'isMotionDetected': isMotionDetected,
    'lastMotionDetected': lastMotionDetected?.toIso8601String(),
  };

  // Create SecurityDevice From JSON.
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

// Enum For The Type Of Security Device.
enum DeviceType {
  camera,
  motionSensor,
  doorLock,
}