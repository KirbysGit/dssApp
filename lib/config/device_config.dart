// TODO: Replace these IPs with your actual device IPs
class DeviceConfig {
  // The IP address of the gadget server (NodeMCU)
  static const String gadgetServerIP = '172.20.10.8';  // Update this with your gadget's IP
  
  // The IP address of the camera (ESP32-CAM)
  static String? cameraIP;  // This will be set dynamically when obtained from the gadget server
  
  // Node MCU devices
  static const List<String> nodeIPs = [
    '172.20.10.8',  // Your gadget's IP
  ];

  // Get the camera stream URL
  static String getCameraStreamUrl() {
    if (cameraIP == null) {
      throw Exception('Camera IP has not been set yet');
    }
    return 'http://$cameraIP/stream';
  }
  
  // Get the gadget server URL for obtaining camera IP
  static String getGadgetServerUrl() {
    return 'http://$gadgetServerIP';
  }

  // Person detection status endpoint
  static String getPersonDetectionStatusUrl() {
    return 'http://$gadgetServerIP/person_status';  // Match the endpoint in gadget.ino
  }

  // Node status URLs
  static String getNodeStatusUrl(String ip) {
    return 'http://$ip/status';
  }
} 