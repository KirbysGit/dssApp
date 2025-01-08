import 'dart:async';
import '../models/security_device.dart';

class MockSecurityService {
  // Mock devices data
  final List<SecurityDevice> _mockDevices = [
    SecurityDevice(
      id: '1',
      name: 'Front Door Camera',
      ipAddress: '192.168.1.100',
      isOnline: true,
      isMotionDetected: false,
    ),
    SecurityDevice(
      id: '2',
      name: 'Backyard Camera',
      ipAddress: '192.168.1.101',
      isOnline: true,
      isMotionDetected: true,
      lastMotionDetected: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    SecurityDevice(
      id: '3',
      name: 'Garage Camera',
      ipAddress: '192.168.1.102',
      isOnline: false,
      isMotionDetected: false,
    ),
  ];

  // Get all devices
  Future<List<SecurityDevice>> getDevices() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return _mockDevices;
  }

  // Simulate device status check
  Future<bool> checkDeviceStatus(SecurityDevice device) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return device.id != '3'; // Mock device 3 as offline
  }

  // Mock image URL for testing UI
  String getMockImageUrl() {
    // Return a placeholder image URL
    return 'https://picsum.photos/800/600';
  }
} 