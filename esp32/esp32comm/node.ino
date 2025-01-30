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
  if (!client.connect("172.20.10.8", 80)) {
    Serial.println("Connection failed");
    esp_camera_fb_return(fb);
    return;
  }

  // Send HTTP POST request
  String head = "POST /capture HTTP/1.1\r\n";
  head += "Host: 172.20.10.8\r\n";
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
  http.begin("http://192.168.1.120/alarm_status");
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
  http.begin("http://192.168.1.120/light_control");
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
  http.begin("http://192.168.1.120/light_control");
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
  server.send(200, "text/plain", "ESP32-CAM Server");
}

// Handle capture request
void handleCapture() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    server.send(500, "text/plain", "Camera capture failed");
    return;
  }

  server.sendHeader("Content-Type", "image/jpeg");
  server.sendHeader("Content-Disposition", "inline; filename=capture.jpg");
  server.setContentLength(fb->len);
  server.send(200);

  // Send the image data in chunks
  const size_t CHUNK_SIZE = 1024;
  size_t remaining = fb->len;
  uint8_t *fbBuf = fb->buf;

  while (remaining > 0) {
    size_t chunk = min(CHUNK_SIZE, remaining);
    server.client().write(fbBuf, chunk);
    fbBuf += chunk;
    remaining -= chunk;
    if (remaining % 1024 == 0) {
      Serial.printf("Sent %d bytes, remaining: %d\n", chunk, remaining);
    }
  }

  esp_camera_fb_return(fb);
  Serial.println("Image sent successfully");
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
}

// Main loop that continously listens for client requests.
void loop()
{
  // Handle incoming HTTP requests.
  // server.handleClient();

  captureAndSendImage();

  delay(10000);

  // (1) If motion is detected by PIR
  // if (digitalRead(PassiveIR_Pin) == HIGH) 
  // {
  //   Serial.println("Motion detected! Capturing and sending image...");
  //   captureAndSendImage();
  // }

  // (2) If ActiveIR sensor is raised.
  // if (digitalRead(ActiveIR_Pin) == HIGH) 
  // {
  //   // Implement logic for Active IR detection (e.g., send notification, trigger alarm)
  //   Serial.println("Active IR sensor triggered!");
  //   triggerAlarm();
  // }

  // (3) If Sound alarm notification received.
  // if (checkAlarmNotification()) 
  // {
  //   if (payload == "start_alarm") 
  //   {
  //     triggerAlarm();
  //   } 
    
  //   else if (payload == "stop_alarm") 
  //   {
  //     digitalWrite(Alarm_Pin, LOW);
  //     Serial.println("Alarm stopped by command.");
  //     digitalWrite(LEDStrip_Pin, LOW);
  //     serial.println("Lights turned off!");
  //   }
  // }

  // (4) If tampered.
  // if (!digitalRead(Tamper_Pin)) 
  // {
  //   Serial.println("Tampering detected!");
  //   triggerAlarm();
  // }

  // (5) Turn on ligths.
  // if (checkForTurnOnLights()) 
  // {
  //   digitalWrite(LEDStrip_Pin, LOW); // Adjust polarity if needed to turn on lights
  //   Serial.println("Turning on lights!");
  //   delay(1000); // Optional: Delay before turning off (adjust as needed)
  //   digitalWrite(LEDStrip_Pin, HIGH); // Turn off lights after delay (optional)
  //   serial.println("Lights turned on!");
  // }

  // (6) Turn off lights.
  // if (checkForTurnOffLights()) 
  // {
  //   digitalWrite(LEDStrip_Pin, LOW); // Turn off lights
  //   Serial.println("Lights turned off!");
  // }
}

// -----------------------------------------------------------------
//                           main.ino(node)
// -----------------------------------------------------------------