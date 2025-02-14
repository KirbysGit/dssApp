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

// Imports. 
#include <WebServer.h>
#include <esp32cam.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <esp_camera.h>
#include <esp_heap_caps.h>
#include "base64.h"

// Photo capture triggered by GPIO pin rising/falling.
// #define TRIGGER_MODE  // Comment out to enable test mode simulation

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz wifi band.

// Kirby's Hotspot.
/*
 * const char* WIFI_SSID = "mi telefono";
 * const char* WIFI_PASS = "password";
 * const char* GADGET_IP = "172.20.10.8";  // Your gadget's IP
*/

// Microrouter Network.

const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";
const char* GADGET_IP = "192.168.8.151";

// Start Web Server on port 80.
WebServer server(80);

// ----------
// RESOLUTION
// ----------
 
// Medium Resolution for better image quality while maintaining performance
// static auto modelRes = esp32cam::Resolution::find(640, 480);  // VGA resolution

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

// Hardware state variables.
bool alarmActive = false;
bool lightsActive = false;
bool motionDetected = false;
unsigned long lastMotionCheck = 0;
const unsigned long MOTION_CHECK_INTERVAL = 500; // Check motion every 500ms

// Heartbeat variables.
unsigned long lastHeartbeat = 0;
const unsigned long HEARTBEAT_INTERVAL = 30000; // Send heartbeat every 30 seconds
const int MAX_MISSED_HEARTBEATS = 5;
int missedHeartbeats = 0;

// ----
// CODE
// ----

// -----------------------------------------------------------------------------------------
// Camera Initialization
// -----------------------------------------------------------------------------------------

bool initCamera() {
    Serial.println("\n========== INITIALIZING CAMERA ==========");
    
    using namespace esp32cam;
    Config cfg;
    cfg.setPins(pins::AiThinker);
    
    // Ensure we explicitly set the resolution to prevent incorrect defaults
    cfg.setResolution(Resolution::find(320, 240));  // QVGA resolution
    cfg.setBufferCount(1);  // Reduce memory usage
    cfg.setJpeg(10);  // Lower quality for better compression
    
    bool success = Camera.begin(cfg);
    if (!success) {
        Serial.println("[ERROR] Camera initialization failed!");
        Serial.println("Possible causes:");
        Serial.println("1. Camera hardware issue");
        Serial.println("2. Power supply issue");
        Serial.println("3. PSRAM issue");
        return false;
    }
    
    // Force the correct resolution and settings after initialization
    sensor_t * s = esp_camera_sensor_get();
    if (s) {
        s->set_framesize(s, FRAMESIZE_QVGA);    // Force 320x240
        s->set_quality(s, 10);                   // Lower quality = better compression
        s->set_brightness(s, 1);                 // Increase brightness slightly
        s->set_saturation(s, 0);                 // Normal saturation
        s->set_contrast(s, 0);                   // Normal contrast
        s->set_special_effect(s, 0);             // No special effects
        s->set_wb_mode(s, 0);                    // Auto White Balance
        s->set_whitebal(s, 1);                   // Enable white balance
        s->set_awb_gain(s, 1);                   // Enable auto white balance gain
        s->set_exposure_ctrl(s, 1);              // Enable auto exposure
        s->set_aec2(s, 1);                       // Enable auto exposure (DSP)
        s->set_gain_ctrl(s, 1);                  // Enable auto gain
        s->set_raw_gma(s, 1);                    // Enable auto gamma correction
        s->set_lenc(s, 1);                       // Enable lens correction
        
        Serial.println("\n[INFO] Camera settings applied:");
        Serial.printf("Resolution: QVGA (320x240)\n");
        Serial.printf("Quality: 10\n");
        Serial.printf("Free PSRAM: %d bytes\n", ESP.getFreePsram());
    } else {
        Serial.println("[ERROR] Failed to get sensor settings!");
        return false;
    }
    
    // Test capture with new settings
    Serial.println("\nPerforming test capture...");
    camera_fb_t *fb = esp_camera_fb_get();
    if (fb) {
        Serial.printf("[INFO] Test capture successful!\n");
        Serial.printf("Image Size: %d bytes\n", fb->len);
        Serial.printf("Resolution: %dx%d\n", fb->width, fb->height);
        Serial.printf("Format: %d (0=JPEG)\n", fb->format);
        
        // Verify image format
        if (fb->format != PIXFORMAT_JPEG) {
            Serial.println("[ERROR] Capture format is not JPEG!");
            esp_camera_fb_return(fb);
            return false;
        }
        
        // Verify resolution
        if (fb->width != 320 || fb->height != 240) {
            Serial.printf("[ERROR] Incorrect resolution: %dx%d (expected 320x240)\n", 
                        fb->width, fb->height);
            esp_camera_fb_return(fb);
            return false;
        }
        
        esp_camera_fb_return(fb);
    } else {
        Serial.println("[ERROR] Test capture failed!");
        return false;
    }
    
    Serial.println("[SUCCESS] Camera initialization complete!");
    Serial.println("======================================\n");
    return true;
}

// -----------------------------------------------------------------------------------------
// Future Functions.
//
// - checkAlarmNotification()
// - checkForTurnOnLights()
// - checkForTurnOffLights()
// - triggerAlarm()
//
// * These have not been implemented into functionality yet w/ Gadget or App *
// -----------------------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------------------

void triggerAlarm() 
{
  // Trigger the alarm (e.g., sound buzzer, flash LED)
  digitalWrite(Alarm_Pin, HIGH);
  Serial.println("Alarm has been sounded.");
  digitalWrite(LEDStrip_Pin, HIGH);
  Serial.println("Lights turned on!");
}

// -----------------------------------------------------------------------------------------
// Handle root endpoint (/)
// -----------------------------------------------------------------------------------------

// Serves as a overall Health Check for the Node.
// Accessed at http://<node-ip>/ should display "ESP32-CAM Node 1".

void handleRoot() {
  server.send(200, "text/plain", "ESP32-CAM Node 1");
}

// -----------------------------------------------------------------------------------------
// Handle capture request. (/capture)
// -----------------------------------------------------------------------------------------

// Capturing Photo & Sending Photo Back As HTTP Response.

void handleCapture() {
    // Attempt to capture a frame from the camera.
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        // If capture fails, send error response.
        server.send(500, "text/plain", "Camera capture failed");
        return;
    }

    // Clear any existing headers to ensure clean response.
    server.client().flush();
    
    // Set required HTTP headers for image transmission
    server.sendHeader("Content-Type", "image/jpeg");  // Specify JPEG format
    server.sendHeader("Access-Control-Allow-Origin", "*");  // Enable CORS
    server.sendHeader("Connection", "close");  // Close connection after sending
    
    // Prepare response with correct content length.
    server.setContentLength(fb->len);
    server.send(200);  // Send success status

    // Get client connection and send image data.
    WiFiClient client = server.client();
    client.write(fb->buf, fb->len);
    
    // Clean up allocated memory and log success.
    esp_camera_fb_return(fb);
    Serial.printf("Sent image: %d bytes\n", fb->len);
}

// -----------------------------------------------------------------------------------------
// Notify gadget of person detection.
// -----------------------------------------------------------------------------------------

// Communication to Gadget of Way to Access Node's Photo.

void notifyGadget() {
    // Ensure Wi-Fi is connected.
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[ERROR] Wi-Fi Disconnected! Cannot send notification.");
        return;
    }

    // Initialize HTTP client.
    HTTPClient http;

    // Construct URLs.
    String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
    String url = "http://" + String(GADGET_IP) + "/person_detected";
    
    // Log URLs.
    Serial.println("Sending notification to gadget...");
    Serial.println("Camera URL: " + cameraUrl);
    Serial.println("Gadget URL: " + url);
    
    // Attempt to begin HTTP connection.
    if (!http.begin(url)) {
        Serial.println("[ERROR] Failed to begin HTTP connection");
        return;
    }
    
    // Add headers.
    http.addHeader("Content-Type", "application/json");
    
    // Create JSON with camera information and timestamp.
    String timestamp = "2025-01-20T12:34:56Z";  // In real implementation, get actual timestamp
    String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\",\"timestamp\":\"" + timestamp + "\"}";
    Serial.println("Sending message: " + message);
    
    // Increase timeout to allow network recovery.
    http.setTimeout(10000);  // 10 seconds
    
    // Send message.
    int httpCode = http.POST(message);
    Serial.printf("HTTP Response code: %d\n", httpCode);
    
    // Case for successful notification.
    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        Serial.println("Server response: " + response);
        Serial.println("Notification sent successfully");
    } else {
        // Case for failed notification.
        Serial.printf("[ERROR] Failed to send notification, HTTP error: %d\n", httpCode);
        if (httpCode > 0) {
            String response = http.getString();
            Serial.println("Server response: " + response);
        }
    }
    
    // End HTTP connection.
    http.end();
}

// -----------------------------------------------------------------------------------------
// Trigger Alarm.
// -----------------------------------------------------------------------------------------

void handleTriggerAlarm() {
    // Print detailed request information
    Serial.println("\n========== TRIGGER ALARM REQUEST ==========");
    Serial.println("Time: " + String(millis()));
    Serial.println("Client IP: " + server.client().remoteIP().toString());
    Serial.println("HTTP Method: " + server.method());
    Serial.println("URI: " + server.uri());
    
    // Print request headers
    Serial.println("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        Serial.printf("%s: %s\n", server.headerName(i).c_str(), server.header(i).c_str());
    }
    
    // Activate alarm
    alarmActive = true;
    digitalWrite(Alarm_Pin, HIGH);
    digitalWrite(RedLED_Pin, HIGH);
    
    // Send detailed response
    String response = "{\"status\":\"alarm_triggered\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    Serial.println("\nResponse sent: " + response);
    Serial.println("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Turn Off Alarm.
// -----------------------------------------------------------------------------------------

void handleTurnOffAlarm() {
    // Print detailed request information
    Serial.println("\n========== TURN OFF ALARM REQUEST ==========");
    Serial.println("Time: " + String(millis()));
    Serial.println("Client IP: " + server.client().remoteIP().toString());
    Serial.println("HTTP Method: " + server.method());
    Serial.println("URI: " + server.uri());
    
    // Print request headers
    Serial.println("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        Serial.printf("%s: %s\n", server.headerName(i).c_str(), server.header(i).c_str());
    }
    
    // Deactivate alarm
    alarmActive = false;
    digitalWrite(Alarm_Pin, LOW);
    digitalWrite(RedLED_Pin, LOW);
    
    // Send detailed response
    String response = "{\"status\":\"alarm_deactivated\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    Serial.println("\nResponse sent: " + response);
    Serial.println("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Turn On Lights.
// -----------------------------------------------------------------------------------------

void handleTurnOnLights() {
    // Print detailed request information
    Serial.println("\n========== TURN ON LIGHTS REQUEST ==========");
    Serial.println("Time: " + String(millis()));
    Serial.println("Client IP: " + server.client().remoteIP().toString());
    Serial.println("HTTP Method: " + server.method());
    Serial.println("URI: " + server.uri());
    
    // Print request headers
    Serial.println("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        Serial.printf("%s: %s\n", server.headerName(i).c_str(), server.header(i).c_str());
    }
    
    // Activate lights
    lightsActive = true;
    digitalWrite(LEDStrip_Pin, HIGH);
    digitalWrite(whitePin, HIGH);
    
    // Send detailed response
    String response = "{\"status\":\"lights_activated\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    Serial.println("\nResponse sent: " + response);
    Serial.println("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Turn Off Lights.
// -----------------------------------------------------------------------------------------

void handleTurnOffLights() {
    // Print detailed request information
    Serial.println("\n========== TURN OFF LIGHTS REQUEST ==========");
    Serial.println("Time: " + String(millis()));
    Serial.println("Client IP: " + server.client().remoteIP().toString());
    Serial.println("HTTP Method: " + server.method());
    Serial.println("URI: " + server.uri());
    
    // Print request headers
    Serial.println("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        Serial.printf("%s: %s\n", server.headerName(i).c_str(), server.header(i).c_str());
    }
    
    // Deactivate lights
    lightsActive = false;
    digitalWrite(LEDStrip_Pin, LOW);
    digitalWrite(whitePin, LOW);
    
    // Send detailed response
    String response = "{\"status\":\"lights_deactivated\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    Serial.println("\nResponse sent: " + response);
    Serial.println("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Heartbeat.
// -----------------------------------------------------------------------------------------

void handleHeartbeat() {
    Serial.println("\n========== HEARTBEAT REQUEST ==========");
    Serial.println("Time: " + String(millis()));
    Serial.println("Client IP: " + server.client().remoteIP().toString());
    
    // Reset missed heart beats counter
    missedHeartbeats = 0;
    
    // Create status JSON
    String response = "{";
    response += "\"status\":\"alive\",";
    response += "\"uptime\":" + String(millis()) + ",";
    response += "\"alarm_active\":" + String(alarmActive ? "true" : "false") + ",";
    response += "\"lights_active\":" + String(lightsActive ? "true" : "false") + ",";
    response += "\"motion_detected\":" + String(motionDetected ? "true" : "false");
    response += "}";
    
    // Send response
    server.send(200, "application/json", response);
    Serial.println("Heartbeat response sent");
    Serial.println("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Set Up Function.
// -----------------------------------------------------------------------------------------

// Main Setup Function.
// Called Upon Power Up or Reset.
void setup()
{
    // Initialize Serial Communication with a larger buffer
    Serial.begin(115200);
    delay(100); // Give serial time to initialize
    Serial.println("\n--------------------------------");
    Serial.println("Starting ESP32-CAM...");
    Serial.println("--------------------------------");

    // Initialize camera with retries.
    bool cameraInitialized = false;
    for (int attempt = 0; attempt < 3 && !cameraInitialized; attempt++) {
        if (attempt > 0) {
            Serial.printf("\nRetrying camera initialization (attempt %d/3)...\n", attempt + 1);
            delay(1000);
        }
        cameraInitialized = initCamera();
    }

    // Case for failed camera initialization.
    if (!cameraInitialized) {
        Serial.println("\n[FATAL] Failed to initialize camera after multiple attempts!");
        Serial.println("Please check power supply and camera hardware.");
        Serial.println("Restarting in 5 seconds...");
        delay(5000);
        ESP.restart();
    }

    // Wi-Fi Configuration.
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    // Wait for Wi-Fi Connection.
    int attempts = 0;
    Serial.print("\nConnecting to WiFi");
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {  // 20-second timeout
        delay(1000);
        Serial.print(".");
        attempts++;
    }

    // Case for successful Wi-Fi connection.
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWi-Fi connected successfully!");
        Serial.print("ESP32-CAM IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\n[ERROR] Wi-Fi connection failed! Restarting...");
        delay(5000);
        ESP.restart();
    }

    // Set up HTTP server endpoints.
    server.on("/", HTTP_GET, handleRoot);
    server.on("/capture", HTTP_GET, handleCapture);
    server.on("/trigger_alarm", HTTP_GET, handleTriggerAlarm);
    server.on("/turn_off_alarm", HTTP_GET, handleTurnOffAlarm);
    server.on("/turn_on_lights", HTTP_GET, handleTurnOnLights);
    server.on("/turn_off_lights", HTTP_GET, handleTurnOffLights);
    server.on("/heartbeat", HTTP_GET, handleHeartbeat);
    
    // Add handler for undefined endpoints
    server.onNotFound([]() {
        Serial.println("\n========== 404 NOT FOUND ==========");
        Serial.println("Time: " + String(millis()));
        Serial.println("Client IP: " + server.client().remoteIP().toString());
        Serial.println("Requested URI: " + server.uri());
        Serial.println("HTTP Method: " + server.method());
        server.send(404, "text/plain", "Endpoint not found");
        Serial.println("==================================\n");
    });
    
    // Start HTTP server.
    server.begin();
    Serial.println("HTTP server started");

    // Register with gadget after Wi-Fi connection.
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nRegistering with gadget...");
        registerWithGadget();
    }

    // Initialize Hardware.
    initializeHardware();
}

// New function to handle gadget registration
void registerWithGadget() {
    HTTPClient http;
    String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
    String url = "http://" + String(GADGET_IP) + "/person_detected";
    
    Serial.println("Camera URL: " + cameraUrl);
    Serial.println("Gadget URL: " + url);
    
    if (!http.begin(url)) {
        Serial.println("[ERROR] Failed to begin HTTP connection");
        return;
    }
    
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(10000);
    
    String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
    Serial.println("Sending registration data...");
    
    int httpCode = http.POST(message);
    Serial.printf("HTTP Response code: %d\n", httpCode);
    
    if (httpCode == HTTP_CODE_OK) {
        // Read response in chunks to avoid buffer overflow
        String response = http.getString();
        Serial.println("Registration successful!");
        Serial.println("Response length: " + String(response.length()) + " bytes");
        
        // Print response in chunks
        const int chunkSize = 128;
        for (size_t i = 0; i < response.length(); i += chunkSize) {
            String chunk = response.substring(i, min(i + chunkSize, response.length()));
            Serial.print(chunk);
            delay(10); // Small delay between chunks
        }
        Serial.println(); // New line after complete response
    } else {
        Serial.printf("[ERROR] Registration failed, code: %d\n", httpCode);
        // Try a few more times if failed
        for(int i = 0; i < 3 && httpCode != HTTP_CODE_OK; i++) {
            delay(1000);
            Serial.printf("Retry attempt %d...\n", i + 1);
            httpCode = http.POST(message);
            if(httpCode == HTTP_CODE_OK) {
                Serial.println("Registration successful on retry!");
                break;
            }
        }
    }
    
    http.end();
    Serial.println("Registration process completed");
}

// -----------------------------------------------------------------------------------------
// Initialize Hardware.
// -----------------------------------------------------------------------------------------

void initializeHardware() {
    Serial.println("\n========== INITIALIZING HARDWARE ==========");
    
    // Initialize input pins.
    pinMode(PassiveIR_Pin, INPUT);
    pinMode(ActiveIR_Pin, INPUT);
    pinMode(Tamper_Pin, INPUT_PULLUP);
    
    // Initialize output pins.
    pinMode(LEDStrip_Pin, OUTPUT);
    pinMode(Alarm_Pin, OUTPUT);
    pinMode(RedLED_Pin, OUTPUT);
    pinMode(whitePin, OUTPUT);
    
    // Set initial states.
    digitalWrite(LEDStrip_Pin, LOW);
    digitalWrite(Alarm_Pin, LOW);
    digitalWrite(RedLED_Pin, LOW);
    digitalWrite(whitePin, LOW);
    
    // Print notification.
    Serial.println("PIR sensors initialized");
    Serial.println("Output devices initialized");
    Serial.println("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// WiFi Connection Check.
// -----------------------------------------------------------------------------------------

void checkWiFiConnection() {
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("[WARNING] Wi-Fi lost! Attempting to reconnect...");
        
        // Disconnect and reconnect
            WiFi.disconnect();
            WiFi.reconnect();
        
        // Attempt to reconnect
            int attempts = 0;
            while (WiFi.status() != WL_CONNECTED && attempts < 20) {
                delay(1000);
                Serial.print(".");
                attempts++;
            }

            if (WiFi.status() == WL_CONNECTED) {
                Serial.println("\nWi-Fi reconnected successfully!");
            Serial.print("ESP32-CAM IP Address: ");
            Serial.println(WiFi.localIP());
            } else {
                Serial.println("\n[ERROR] Failed to reconnect. Restarting...");
                delay(5000);
                ESP.restart();
            }
        }
    }

// -----------------------------------------------------------------------------------------
// Test Person Detection (For Mobile App Testing)
// -----------------------------------------------------------------------------------------

void simulatePersonDetection() {
    static unsigned long lastTestDetection = 0;
    const unsigned long TEST_INTERVAL = 30000; // 30 second interval
    
    if (millis() - lastTestDetection >= TEST_INTERVAL) {
        lastTestDetection = millis();
        Serial.println("\n[TEST] Simulating person detection...");
        
        // Simulate motion detection
        motionDetected = true;
        
        // Capture test image
        camera_fb_t *fb = esp_camera_fb_get();
        if (!fb) {
            Serial.println("[TEST] Camera capture failed");
        } else {
            Serial.println("[TEST] Image captured successfully");
            Serial.printf("[TEST] Image size: %d bytes\n", fb->len);
            
            // Notify gadget
            notifyGadget();
            
            // Return the frame buffer
            esp_camera_fb_return(fb);
            
            Serial.println("[TEST] Test detection notification sent");
        }
        
        // Reset motion detection after a short delay
        delay(1000);  // Keep motion detected true briefly for status checks
        motionDetected = false;
    }
}

// -----------------------------------------------------------------------------------------
// Check Motion Sensor.
// -----------------------------------------------------------------------------------------

void checkMotionSensor() {
    // Check motion sensor at regular intervals.

    /*
    if (millis() - lastMotionCheck >= MOTION_CHECK_INTERVAL) {
        lastMotionCheck = millis();
        
        // Read PIR sensor.
        int pirValue = digitalRead(PassiveIR_Pin);
        if (pirValue == HIGH) {
            Serial.println("\n[MOTION] PIR sensor detected motion");
            motionDetected = true;
            
            // Capture image.
            camera_fb_t *fb = esp_camera_fb_get();
            if (!fb) {
                Serial.println("[ERROR] Camera capture failed");
            } else {
                Serial.println("Image captured successfully");
                Serial.printf("Image size: %d bytes\n", fb->len);
                
                // Process image for person detection.
                if (processImage(fb)) {
                    Serial.println("[DETECTION] Person detected in image");
                    
                    // Notify gadget.
                    notifyGadget();
                    
                    // Turn on lights if it's dark (you can add light sensor logic here).
                    if (!lightsActive) {
                        digitalWrite(LEDStrip_Pin, HIGH);
                        digitalWrite(whitePin, HIGH);
                        lightsActive = true;
                    }
                } else {
                    Serial.println("No person detected in image");
                }
                
                // Return the frame buffer
                esp_camera_fb_return(fb);
            }
        } else {
            motionDetected = false;
        }
    }
    */
}

// -----------------------------------------------------------------------------------------
// Main Loop.
// -----------------------------------------------------------------------------------------

// After Setup, Main Loop Continues to Run actively processing requests.

void loop()
{
    // 1. Check Wi-Fi Connection and Reconnect if Disconnected
    static unsigned long lastWiFiCheck = 0;
    const unsigned long WIFI_CHECK_INTERVAL = 10000; // Check every 10 seconds
    
    if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) {
        lastWiFiCheck = millis();
        checkWiFiConnection();
    }

    // 2. Handle incoming HTTP requests with status indicator
    static unsigned long lastRequestTime = 0;
    static bool isHandlingRequest = false;
    
    if (server.client()) {
        if (!isHandlingRequest) {
            isHandlingRequest = true;
            lastRequestTime = millis();
            digitalWrite(RedLED_Pin, HIGH); // Visual indicator that we're handling a request
        }
    }
    
    server.handleClient();
    
    if (isHandlingRequest && millis() - lastRequestTime > 100) {
        isHandlingRequest = false;
        digitalWrite(RedLED_Pin, LOW);
    }
    
    // 3. Check motion sensor at regular intervals
    checkMotionSensor();
    
    // 4. Check heartbeat.
    if (millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) {
        lastHeartbeat = millis();
        missedHeartbeats++;
        
        if (missedHeartbeats >= MAX_MISSED_HEARTBEATS) {
            Serial.println("[WARNING] Multiple heartbeats missed. Checking WiFi connection...");
            checkWiFiConnection();
        }
    }
    
    // 5. Handle alarm state.
    if (alarmActive) {
        // Toggle alarm for audible effect and LED for visual feedback.
        static unsigned long lastAlarmToggle = 0;
        if (millis() - lastAlarmToggle >= 500) {  // Toggle every 500ms
            lastAlarmToggle = millis();
            digitalWrite(Alarm_Pin, !digitalRead(Alarm_Pin));
            digitalWrite(RedLED_Pin, !digitalRead(RedLED_Pin));
            // Also flash the white LED for additional visibility
            digitalWrite(whitePin, !digitalRead(whitePin));
        }
    }
    
    // Uncomment this section to test person detection notifications with the mobile app
    // 6. Test person detection simulation
    simulatePersonDetection();
    
    
    // Small delay to prevent overwhelming the CPU
    delay(100);
}

// -----------------------------------------------------------------
//                           main.ino(node)
// -----------------------------------------------------------------