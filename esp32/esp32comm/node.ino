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
// #define TRIGGER_MODE  // Comment out to enable test mode simulation

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz wifi band.
//const char* WIFI_SSID = "mi telefono";
//const char* WIFI_PASS = "password";
//const char* GADGET_IP = "172.20.10.8";  // Your gadget's IP

const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";
const char* GADGET_IP = "192.168.8.151";

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
    // Ensure Wi-Fi is connected
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[ERROR] Wi-Fi Disconnected! Cannot send image.");
        return;
    }

    // Capture image using ESP32-CAM library
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("[ERROR] Failed to capture image");
        return;
    }

    uint8_t* imageData = fb->buf;
    size_t imageSize = fb->len;

    Serial.printf("Captured image size: %d bytes\n", imageSize);
    Serial.print("First 32 bytes of image: ");
    for (int i = 0; i < min(32, (int)imageSize); i++) {
        Serial.printf("%02X ", imageData[i]);
    }
    Serial.println();

    // Verify JPEG header
    if (imageSize < 3 || imageData[0] != 0xFF || imageData[1] != 0xD8 || imageData[2] != 0xFF) {
        Serial.println("[ERROR] Invalid JPEG format");
        esp_camera_fb_return(fb);
        return;
    }

    WiFiClient client;
    Serial.println("Connecting to server...");
    
    if (!client.connect(GADGET_IP, 80)) {
        Serial.println("[ERROR] Connection to gadget failed");
        esp_camera_fb_return(fb);
        return;
    }

    // Build the HTTP header with exact Content-Length
    String head = "POST /capture HTTP/1.1\r\n";
    head += "Host: " + String(GADGET_IP) + "\r\n";
    head += "Content-Type: image/jpeg\r\n";
    head += "Content-Length: " + String(imageSize) + "\r\n";
    head += "Connection: close\r\n\r\n";

    // Debug headers
    Serial.println("\nSending HTTP headers:");
    Serial.println(head);
    
    // Send the headers
    client.print(head);
    
    // Send the image data in chunks
    const size_t chunkSize = 1024;
    size_t bytesSent = 0;
    
    Serial.printf("Starting to send %d bytes of image data...\n", imageSize);
    
    while (bytesSent < imageSize) {
        size_t bytesToSend = min(chunkSize, imageSize - bytesSent);
        size_t sent = client.write(imageData + bytesSent, bytesToSend);
        
        if (sent == 0) {
            Serial.println("[ERROR] Failed to send data chunk");
            client.stop();
            esp_camera_fb_return(fb);
            return;
        }
        
        bytesSent += sent;
        if (bytesSent % 4096 == 0) {  // Print progress every 4KB
            Serial.printf("Sent %d/%d bytes (%.1f%%)\n", 
                        bytesSent, imageSize, 
                        (bytesSent * 100.0) / imageSize);
        }
        yield();  // Allow background tasks to run
    }
    
    Serial.printf("Completed sending %d bytes\n", bytesSent);

    // Wait for server response with timeout
    unsigned long timeout = millis();
    bool responseReceived = false;
    String responseStatus = "";
    
    while (millis() - timeout < 10000) {  // 10 second timeout
        if (client.available()) {
            responseReceived = true;
            String line = client.readStringUntil('\n');
            if (responseStatus.isEmpty() && line.startsWith("HTTP/1.1")) {
                responseStatus = line;
            }
            Serial.println("Server: " + line);
        }
        
        if (responseReceived && !client.available()) {
            break;
        }
        
        yield();
    }

    if (!responseReceived) {
        Serial.println("[ERROR] Server response timeout");
    } else {
        Serial.println("Response status: " + responseStatus);
    }

    // Clean up
    client.stop();
    esp_camera_fb_return(fb);
    Serial.println("Image transfer completed");
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
    // Ensure Wi-Fi is connected
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[ERROR] Wi-Fi Disconnected! Cannot send notification.");
        return;
    }

    HTTPClient http;
    String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
    String url = "http://" + String(GADGET_IP) + "/person_detected";
    
    Serial.println("Sending notification to gadget...");
    Serial.println("Camera URL: " + cameraUrl);
    Serial.println("Gadget URL: " + url);
    
    if (!http.begin(url)) {
        Serial.println("[ERROR] Failed to begin HTTP connection");
        return;
    }
    
    http.addHeader("Content-Type", "application/json");
    
    // Create JSON with camera information
    String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
    Serial.println("Sending message: " + message);
    
    // Increase timeout to allow network recovery
    http.setTimeout(10000);  // 10 seconds
    
    int httpCode = http.POST(message);
    Serial.printf("HTTP Response code: %d\n", httpCode);
    
    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        Serial.println("Server response: " + response);
        Serial.println("Notification sent successfully");
    } else {
        Serial.printf("[ERROR] Failed to send notification, HTTP error: %d\n", httpCode);
        if (httpCode > 0) {
            String response = http.getString();
            Serial.println("Server response: " + response);
        }
    }
    
    http.end();
    
    // After notifying, capture and send the image only if notification was successful
    if (httpCode == HTTP_CODE_OK) {
        captureAndSendImage();
    }
}

// Setup function that initializes esp32-cam.
void setup()
{
    Serial.begin(115200);
    Serial.println("--------------------------------");
    Serial.println("Starting ESP32-CAM...");
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

    // Wi-Fi Configuration
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    // Wait for Wi-Fi Connection
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {  // 20-second timeout
        delay(1000);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWi-Fi connected successfully!");
        Serial.print("ESP32-CAM IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\n[ERROR] Wi-Fi connection failed! Restarting...");
        delay(5000);
        ESP.restart();
    }

    // Set up HTTP server endpoints
    server.on("/", HTTP_GET, handleRoot);
    server.on("/capture", HTTP_GET, handleCapture);
    
    server.begin();
    Serial.println("HTTP server started");

    // Register with gadget after WiFi connection
    if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
        String url = "http://" + String(GADGET_IP) + "/person_detected";
        
        Serial.println("\nRegistering camera with gadget...");
        Serial.println("Camera URL: [" + cameraUrl + "]");
        Serial.println("Gadget URL: [" + url + "]");
        
        if (!http.begin(url)) {
            Serial.println("Failed to begin HTTP connection to gadget");
            return;
        }
        
        http.addHeader("Content-Type", "application/json");
        http.setTimeout(10000);  // 10 second timeout
        
        // Send registration message with proper JSON formatting
        String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
        Serial.println("Sending registration message: " + message);
        
        int httpCode = http.POST(message);
        Serial.printf("HTTP Response code: %d\n", httpCode);
        
        if (httpCode == HTTP_CODE_OK) {
            String response = http.getString();
            Serial.println("Gadget response: " + response);
            Serial.println("Camera registered successfully with gadget");
        } else {
            Serial.printf("Failed to register camera with gadget, error code: %d\n", httpCode);
            // Try a few more times if failed
            for(int i = 0; i < 3 && httpCode != HTTP_CODE_OK; i++) {
                delay(1000);
                Serial.printf("Retry attempt %d...\n", i + 1);
                httpCode = http.POST(message);
                if(httpCode == HTTP_CODE_OK) {
                    String response = http.getString();
                    Serial.println("Gadget response: " + response);
                    Serial.println("Camera registered successfully on retry");
                    break;
                }
            }
        }
        
        http.end();
    }

    // Initialize PIR sensor pin if using TRIGGER_MODE
    #ifdef TRIGGER_MODE
    pinMode(PassiveIR_Pin, INPUT);
    Serial.println("PIR sensor initialized");
    #endif
}

// Main loop that continously listens for client requests.
void loop()
{
    // Check Wi-Fi Connection and Reconnect if Disconnected
    static unsigned long lastWiFiCheck = 0;
    if (millis() - lastWiFiCheck > 10000) {  // Check every 10 seconds
        lastWiFiCheck = millis();
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("[WARNING] Wi-Fi lost! Attempting to reconnect...");
            WiFi.disconnect();
            WiFi.reconnect();
            int attempts = 0;
            while (WiFi.status() != WL_CONNECTED && attempts < 20) {
                delay(1000);
                Serial.print(".");
                attempts++;
            }

            if (WiFi.status() == WL_CONNECTED) {
                Serial.println("\nWi-Fi reconnected successfully!");
            } else {
                Serial.println("\n[ERROR] Failed to reconnect. Restarting...");
                delay(5000);
                ESP.restart();
            }
        }
    }

    server.handleClient();
    
    // For testing without PIR sensor, use timer-based detection
    #ifndef TRIGGER_MODE
    static unsigned long lastDetection = 0;
    unsigned long currentMillis = millis();
    
    if (currentMillis - lastDetection > 10000) {  // Every 10 seconds
        if (WiFi.status() == WL_CONNECTED) {  // Only notify if WiFi is connected
            Serial.println("\n----------------------------");
            Serial.println("Test: Simulating motion detection");
            Serial.println("----------------------------");
            notifyGadget();
        }
        lastDetection = currentMillis;
    }
    #endif
    
    // Small delay to prevent overwhelming the system
    delay(100);
}

// -----------------------------------------------------------------
//                           main.ino(node)
// -----------------------------------------------------------------