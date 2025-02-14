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
// Setup function that initializes ESP32-CAM.
// -----------------------------------------------------------------------------------------

// Main Setup Function.
// Called Upon Power Up or Reset.
void setup()
{
    // Initialize Serial Communication.
    Serial.begin(115200);
    Serial.println("--------------------------------");
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

    // Wi-Fi Configuration
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    // Wait for Wi-Fi Connection.
    int attempts = 0;
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
    
    // Start HTTP server.
    server.begin();
    Serial.println("HTTP server started");

    // Register with gadget after Wi-Fi connection.
    if (WiFi.status() == WL_CONNECTED) {
        // Initialize HTTP client.
        HTTPClient http;

        // Construct URLs.
        String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
        String url = "http://" + String(GADGET_IP) + "/person_detected";
        
        // Log URLs.
        Serial.println("\nRegistering camera with gadget...");
        Serial.println("Camera URL: [" + cameraUrl + "]");
        Serial.println("Gadget URL: [" + url + "]");
        
        // Attempt to begin HTTP connection.
        if (!http.begin(url)) {
            Serial.println("Failed to begin HTTP connection to gadget");
            return;
        }

        // Add headers.
        http.addHeader("Content-Type", "application/json");
        http.setTimeout(10000);  // 10 second timeout
        
        // Send registration message with proper JSON formatting.
        String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
        Serial.println("Sending registration message: " + message);
        
        // Send message.
        int httpCode = http.POST(message);
        Serial.printf("HTTP Response code: %d\n", httpCode);
        
        // Case for successful registration.
        if (httpCode == HTTP_CODE_OK) {
            String response = http.getString();
            Serial.println("Gadget response: " + response);
            Serial.println("Camera registered successfully with gadget");
        } else {
            // Case for failed registration.
            Serial.printf("Failed to register camera with gadget, error code: %d\n", httpCode);
            // Try a few more times if failed.
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
        
        // End HTTP connection.
        http.end();
    }

    // Initialize PIR sensor pin if using TRIGGER_MODE
    #ifdef TRIGGER_MODE
    pinMode(PassiveIR_Pin, INPUT);
    Serial.println("PIR sensor initialized");
    #endif
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
// Main Loop.
// -----------------------------------------------------------------------------------------

// After Setup, Main Loop Continues to Run actively processing requests.

void loop()
{
    // 1. WiFi Management.
    static unsigned long lastWiFiCheck = 0;
    const unsigned long WIFI_CHECK_INTERVAL = 10000; // 10 seconds
    
    if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) {
        checkWiFiConnection();
        lastWiFiCheck = millis();
    }

    // 2. Server Handling.
    server.handleClient();
    
    // 3. Detection Simulation (Test Mode).
    #ifndef TRIGGER_MODE
    static unsigned long lastDetection = 0;
    const unsigned long DETECTION_INTERVAL = 45000; // 45 seconds
    
    if (millis() - lastDetection > DETECTION_INTERVAL) {
        if (WiFi.status() == WL_CONNECTED) {
            notifyGadget();
        }
        lastDetection = millis();
    }
    #endif

    // 4. Basic delay to prevent overwhelming the system
    delay(100);
}

// -----------------------------------------------------------------
//                           main.ino(node)
// -----------------------------------------------------------------