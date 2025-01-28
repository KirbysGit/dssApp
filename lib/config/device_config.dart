// TODO: Replace these IPs with your actual device IPs
class DeviceConfig {
  // Main gadget server (NodeMCU)
  static const String gadgetServerIP = '192.168.1.100';  // This will provide the camera IP
  
  // ESP32-CAM IP (will be obtained from gadget server)
  static String? cameraIP;  // This will be set dynamically
  
  // Node MCU devices
  static const List<String> nodeIPs = [
    '192.168.1.101',  // Back door node
    '192.168.1.102',  // Motion sensor node
  ];

  // Camera stream URL
  static String getCameraStreamUrl() {
    if (cameraIP == null) {
      throw Exception('Camera IP not yet obtained from gadget server');
    }
    return 'http://$cameraIP/stream';  // ESP32-CAM stream endpoint
  }

  // Gadget server URL to get camera IP
  static String getGadgetServerUrl() {
    return 'http://$gadgetServerIP/camera-ip';  // Endpoint that returns camera IP
  }

  // Node status URLs
  static String getNodeStatusUrl(String ip) {
    return 'http://$ip/status';  // NodeMCU API endpoint
  }
} 