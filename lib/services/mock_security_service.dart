import 'dart:async';
import '../models/security_device.dart';
import '../config/device_config.dart';

class MockSecurityService {
  Future<void> initializeCameraIP() async {
    // In real implementation, this will fetch camera IP from gadget server
    await Future.delayed(const Duration(seconds: 1));
    DeviceConfig.cameraIP = '192.168.1.200'; // This will come from gadget server
  }

  Future<List<SecurityDevice>> getDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      // ESP32-CAM (IP obtained from gadget server)
      SecurityDevice(
        id: '1',
        name: 'Security Camera',
        type: DeviceType.camera,
        ipAddress: DeviceConfig.cameraIP ?? 'Not connected',
        isOnline: DeviceConfig.cameraIP != null,
        isMotionDetected: false,
      ),
      // Gadget Server (NodeMCU)
      SecurityDevice(
        id: '2',
        name: 'Gadget Server',
        type: DeviceType.motionSensor,
        ipAddress: DeviceConfig.gadgetServerIP,
        isOnline: true,
        isMotionDetected: true,
        lastMotionDetected: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      // Additional Node MCU devices
      SecurityDevice(
        id: '3',
        name: 'Motion Sensor Node',
        type: DeviceType.motionSensor,
        ipAddress: DeviceConfig.nodeIPs[0],
        isOnline: true,
        isMotionDetected: false,
      ),
    ];
  }

  Future<bool> checkDeviceStatus(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (deviceId == '1') {
      return DeviceConfig.cameraIP != null;
    }
    return true;
  }

  // Mock image URL for testing UI
  String getMockImageUrl() {
    // Return a placeholder image URL
    return 'https://picsum.photos/800/600';
  }

  String getCameraStreamUrl() {
    return DeviceConfig.getCameraStreamUrl();
  }
} 