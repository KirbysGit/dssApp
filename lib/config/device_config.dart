// TODO: Replace these IPs with your actual device IPs
class DeviceConfig {
  // Main gadget server (NodeMCU)
  static const String gadgetServerIP = '172.20.10.8';  // Your NodeMCU's actual IP
  
  // ESP32-CAM IP (will be obtained from gadget server)
  static String? cameraIP;  // This will be set dynamically
  
  // Node MCU devices
  static const List<String> nodeIPs = [
    '172.20.10.8',  // Your gadget's IP
  ];

  // Camera stream URL
  static String getCameraStreamUrl() {
    if (cameraIP == null) {
      throw Exception('Camera IP not yet obtained from gadget server');
    }
    return 'http://$cameraIP/stream';  // ESP32-CAM stream endpoint
  }

  // Gadget server endpoints
  static String getGadgetServerUrl() {
    return 'http://$gadgetServerIP';  // Base URL for the gadget server
  }

  // Person detection status endpoint
  static String getPersonDetectionStatusUrl() {
    return 'http://$gadgetServerIP/person-status';  // Endpoint we defined in the gadget
  }

  // Node status URLs
  static String getNodeStatusUrl(String ip) {
    return 'http://$ip/status';
  }
} 