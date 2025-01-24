import 'dart:async';
import '../models/security_device.dart';

class MockSecurityService {
  // Get all devices
  Future<List<SecurityDevice>> getDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      SecurityDevice(
        id: '1',
        name: 'Front Door Camera',
        type: DeviceType.camera,
        ipAddress: '192.168.1.100',
        isOnline: true,
        isMotionDetected: false,
      ),
      SecurityDevice(
        id: '2',
        name: 'Back Door Camera',
        type: DeviceType.camera,
        ipAddress: '192.168.1.101',
        isOnline: true,
        isMotionDetected: true,
        lastMotionDetected: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      SecurityDevice(
        id: '3',
        name: 'Motion Sensor 1',
        type: DeviceType.motionSensor,
        ipAddress: '192.168.1.102',
        isOnline: true,
        isMotionDetected: false,
      ),
    ];
  }

  // Simulate device status check
  Future<bool> checkDeviceStatus(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Simulating all devices are online
  }

  // Mock image URL for testing UI
  String getMockImageUrl() {
    // Return a placeholder image URL
    return 'https://picsum.photos/800/600';
  }
} 