// -----------------------------------------------------------------
//                           main.ino(node)
//
//
// Description: Central point where the code runs on our 
//              esp32-cam nodes.
//
// Name:         Date:           Description:
// -----------   ---------       ----------------
// Jaxon Topel   9/12/2024       Initial Creation
// Jaxon Topel   9/13/2023       Setup Wifi/ESP32 connection
// Jaxon Topel   1/13/2025       Architect Communication Network for Node/Gadget
// Jaxon Topel   1/17/2025       Communication Network Debugging and Data integrity checks
// Jaxon Topel   1/20/2025       Sending image from Node to Gadget
//
// Note(1): ChatGPT aided in the development of this code.
// Note(2): To run this code in arduino ide, please use ai
// thinker cam, 115200 baud rate to analyze serial communication,
// and enter both the password and wifi to work within the network.
//
// -----------------------------------------------------------------

#include <WebServer.h>
#include <esp32cam.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <esp_camera.h>

// Photo capture triggered by GPIO pin rising/falling.
#define TRIGGER_MODE

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz wifi band.
const char* WIFI_SSID = "mi telefono";
const char* WIFI_PASS = "password";
const char* GADGET_IP = "172.20.10.8";  // Your gadget's IP

// Server on port 80.
WebServer server(80);

// ----------
// RESOLUTION
// ----------
 
// Medium Resolution for better image quality while maintaining performance
static auto modelRes = esp32cam::Resolution::find(640, 480);  // VGA resolution

// ---------
// CONSTANTS
// ---------

// Passive IR sensor pin.
const byte PassiveIR_Pin = GPIO_NUM_4;

// Active IR sensor pin.
const byte ActiveIR_Pin = GPIO_NUM_2;

// Clock
const byte Clock_Pin = GPIO_NUM_14;

// White LED Strip
const byte LEDStrip_Pin = GPIO_NUM_15;

// Alarm (Buzzer)
const byte Alarm_Pin = GPIO_NUM_13;

// Small Red led near reset button.
const byte RedLED_Pin = GPIO_NUM_12;

// Front facing white led.
const byte whitePin = GPIO_NUM_3;

// Tampering pin.
const byte Tamper_Pin = GPIO_NUM_1;

// ----
// CODE
// ----

// Capture and send image when PIR detects motion.
void captureAndSendImage() 
{
  // Capture image using ESP32-CAM library
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb)
  {
    Serial.println("Failed to capture image");
    return;
  }

  // Get image data and size
  uint8_t* imageData = fb->buf;
  size_t imageSize = fb->len;

  // Debug print
  Serial.printf("Captured image size: %d bytes\n", imageSize);
  Serial.print("First 32 bytes of image: ");
  for (int i = 0; i < min(32, (int)imageSize); i++) {
    Serial.printf("%02X ", imageData[i]);
  }
  Serial.println();

  WiFiClient client;
  
  Serial.println("Connecting to server...");
  if (!client.connect(GADGET_IP, 80)) {
    Serial.println("Connection failed");
    esp_camera_fb_return(fb);
    return;
  }

  // Send HTTP POST request
  String head = "POST /capture HTTP/1.1\r\n";
  head += "Host: " + String(GADGET_IP) + "\r\n";
  head += "Content-Type: image/jpeg\r\n";
  head += "Content-Length: " + String(imageSize) + "\r\n";
  head += "Connection: close\r\n\r\n";
  
  client.print(head);
  
  // Send the image data
  uint8_t *fbBuf = fb->buf;
  size_t fbLen = fb->len;
  for (size_t n=0; n<fbLen; n=n+1024) {
    if (n+1024 < fbLen) {
      client.write(fbBuf, 1024);
      fbBuf += 1024;
    }
    else if (fbLen%1024>0) {
      size_t remainder = fbLen%1024;
      client.write(fbBuf, remainder);
    }
  }
  
  // Wait for server response
  unsigned long timeout = millis();
  while (client.available() == 0) {
    if (millis() - timeout > 5000) {
      Serial.println("Client Timeout!");
      client.stop();
      esp_camera_fb_return(fb);
      return;
    }
  }

  // Read server response
  Serial.println("Server Response:");
  while (client.available()) {
    String line = client.readStringUntil('\n');
    Serial.println(line);
  }

  // Clean up
  client.stop();
  esp_camera_fb_return(fb);
  Serial.println("Image send attempt completed");
}

bool checkAlarmNotification() 
{
  // Example using HTTP GET request:
  HTTPClient http;
  http.begin("http://" + String(GADGET_IP) + "/alarm_status");
  int httpCode = http.GET();

  if (httpCode == HTTP_CODE_OK) 
  {
    String payload = http.getString();

    // Case for sounding the alarm.
    if (payload == "start_alarm") 
    {
      return true;
    }

    // Case for stopping the alarm.
    else if (payload == "stop_alarm") 
    {
      return true;
    }
  }

  return false;
}

bool checkForTurnOnLights() 
{
  // Check for "turn_on_lights" message:
  HTTPClient http;
  http.begin("http://" + String(GADGET_IP) + "/light_control");
  int httpCode = http.GET();

  if (httpCode == HTTP_CODE_OK) 
  {
    String payload = http.getString();
    if (payload == "turn_on_lights") 
    {
      return true;
    }
  }

  return false;
} 

bool checkForTurnOffLights() 
{
  // Check for "turn_off_lights" message:
  HTTPClient http;
  http.begin("http://" + String(GADGET_IP) + "/light_control");
  int httpCode = http.GET();

  if (httpCode == HTTP_CODE_OK) 
  {
    String payload = http.getString();
    if (payload == "turn_off_lights") 
    {
      return true;
    }
  }

  return false;
}

void triggerAlarm() 
{
  // Trigger the alarm (e.g., sound buzzer, flash LED)
  digitalWrite(Alarm_Pin, HIGH);
  Serial.println("Alarm has been sounded.");
  digitalWrite(LEDStrip_Pin, HIGH);
  Serial.println("Lights turned on!");
}

// Handle root
void handleRoot() {
  server.send(200, "text/plain", "ESP32-CAM Node 1");
}

// Handle capture request
void handleCapture() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    server.send(500, "text/plain", "Camera capture failed");
    return;
  }

  // Clear any existing headers
  server.client().flush();
  
  // Set headers properly
  server.sendHeader("Content-Type", "image/jpeg");
  server.sendHeader("Content-Length", String(fb->len));
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Connection", "close");
  
  // Send the response code without content
  server.setContentLength(fb->len);
  server.send(200);

  // Send the image data
  WiFiClient client = server.client();
  client.write(fb->buf, fb->len);
  
  // Clean up
  esp_camera_fb_return(fb);
  Serial.printf("Sent image: %d bytes\n", fb->len);
}

// Notify gadget of person detection
void notifyGadget() {
  HTTPClient http;
  String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
  String url = "http://" + String(GADGET_IP) + "/person_detected";
  
  Serial.println("Sending notification to gadget...");
  Serial.println("Camera URL: " + cameraUrl);
  Serial.println("Gadget URL: " + url);
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON with camera information
  String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
  Serial.println("Sending message: " + message);
  
  int httpCode = http.POST(message);
  
  if (httpCode == HTTP_CODE_OK) {
    Serial.println("Notification sent successfully");
    
    // After successful notification, capture and send an image
    captureAndSendImage();
  } else {
    Serial.printf("Failed to send notification, error code: %d\n", httpCode);
  }
  
  http.end();
}

// Setup function that initializes esp32-cam.
void setup()
{
  Serial.begin(115200);
  Serial.println("--------------------------------");
  Serial.println("Serial communication starting...");
  Serial.println("--------------------------------");

  // Configure ESP32-CAM.
  {
    using namespace esp32cam;
    Config cfg;

    // Set pin configuration for AI thinker model.
    cfg.setPins(pins::AiThinker);

    // Set resolution to high.
    cfg.setResolution(modelRes);
    
    // Buffer count for image processing.
    cfg.setBufferCount(2);

    // Set image quality to 80%.
    cfg.setJpeg(80);

    bool ok = Camera.begin(cfg);
    Serial.println(ok ? "Camera initialization successful" : "Camera initialization failed");
  }

  // Configure wifi connection
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  // Wait for wifi to connect
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected");
  Serial.print("Camera Stream Ready! Go to: http://");
  Serial.println(WiFi.localIP());

  // Set up HTTP server endpoints
  server.on("/", HTTP_GET, handleRoot);
  server.on("/capture", HTTP_GET, handleCapture);
  
  server.begin();
  Serial.println("HTTP server started");

  // Register with gadget after WiFi connection
  HTTPClient http;
  String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
  String url = "http://" + String(GADGET_IP) + "/person_detected";
  
  Serial.println("Registering camera with gadget...");
  Serial.println("Camera URL: " + cameraUrl);
  Serial.println("Gadget URL: " + url);
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Send registration message
  String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
  Serial.println("Sending registration: " + message);
  
  int httpCode = http.POST(message);
  
  if (httpCode == HTTP_CODE_OK) {
    Serial.println("Camera registered successfully with gadget");
  } else {
    Serial.printf("Failed to register camera with gadget, error code: %d\n", httpCode);
    // Try a few more times if failed
    for(int i = 0; i < 3 && httpCode != HTTP_CODE_OK; i++) {
      delay(1000);
      httpCode = http.POST(message);
      if(httpCode == HTTP_CODE_OK) {
        Serial.println("Camera registered successfully on retry");
        break;
      }
    }
  }
  
  http.end();

  // Initialize PIR sensor pin if using TRIGGER_MODE
  #ifdef TRIGGER_MODE
  pinMode(PassiveIR_Pin, INPUT);
  Serial.println("PIR sensor initialized");
  #endif
}

// Main loop that continously listens for client requests.
void loop()
{
  server.handleClient();
  
  // Check PIR sensor (if connected)
  static bool lastPIRState = false;
  bool pirState = digitalRead(PassiveIR_Pin);
  
  if (pirState != lastPIRState) {
    if (pirState == HIGH) {
      Serial.println("Motion detected!");
      notifyGadget();  // This will also trigger image capture
    }
    lastPIRState = pirState;
  }
  
  // For testing without PIR sensor, use timer-based detection
  #ifndef TRIGGER_MODE
  static unsigned long lastDetection = 0;
  if (millis() - lastDetection > 10000) {  // Every 10 seconds for testing
    Serial.println("Test: Simulating motion detection");
    notifyGadget();
    lastDetection = millis();
  }
  #endif
  
  // Small delay to prevent overwhelming the system
  delay(100);
}

// -----------------------------------------------------------------
//                           main.ino(node)
// -----------------------------------------------------------------