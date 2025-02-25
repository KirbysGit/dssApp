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

// Image Processing Imports.
#include "edge-impulse-sdk/dsp/image/image.hpp"
#include <Person_detector_x1_inferencing.h>

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
const byte PassiveIR_Pin = GPIO_NUM_12;

// Active IR sensor pin #1.
const byte ActiveIR1_Pin = GPIO_NUM_14;

// Active IR sensor pin #2.
const byte ActiveIR2_Pin = GPIO_NUM_4;

// White LED Strip.
const byte LEDStrip_Pin = GPIO_NUM_15;

// Alarm (Buzzer).
const byte Alarm_Pin = GPIO_NUM_13;

// Test LED #1.
const byte TestLED1_Pin = GPIO_NUM_2;

// Test LED #2.
const byte TestLED2_Pin = GPIO_NUM_16;

// Chip Enable.
const byte ChipEnable_Pin = GPIO_NUM_0;

// Front facing white led.
//const byte whitePin = GPIO_NUM_3;

// Tampering pin.
//const byte Tamper_Pin = GPIO_NUM_1;

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

// ----------------------------------------------------------------------------------------
// Helper Functions.
// ----------------------------------------------------------------------------------------

void serialPrintWithDelay(const String& message, bool newLine = true, int delayMs = 10) {
    if (newLine) {
        Serial.println(message);
    } else {
        Serial.print(message);
    }
    Serial.flush();
    delay(delayMs);  // Allow time for the buffer to clear
}

void printChunked(const String& message, int chunkSize = 32) {
    for (size_t i = 0; i < message.length(); i += chunkSize) {
        String chunk = message.substring(i, min(i + chunkSize, message.length()));
        serialPrintWithDelay(chunk, false, 5);
    }
    serialPrintWithDelay("", true, 10);  // Final newline
}

// -----------------------------------------------------------------------------------------
// Camera Initialization
// -----------------------------------------------------------------------------------------

bool initCamera() {
    serialPrintWithDelay("\n========== INITIALIZING CAMERA ==========");
    
    // Initialize camera configuration.
    using namespace esp32cam;
    Config cfg;
    cfg.setPins(pins::AiThinker);
    
    // Set resolution.
    cfg.setResolution(Resolution::find(320, 240));  // QVGA resolution
    cfg.setBufferCount(1);  // Reduce memory usage
    cfg.setJpeg(10);  // Lower quality for better compression
    
    // Initialize camera.
    bool success = Camera.begin(cfg);
    if (!success) {
        serialPrintWithDelay("[ERROR] Camera initialization failed!");
        serialPrintWithDelay("Possible causes:");
        serialPrintWithDelay("1. Camera hardware issue");
        serialPrintWithDelay("2. Power supply issue");
        serialPrintWithDelay("3. PSRAM issue");
        return false;
    }
    
    // Force Resolution & Quality.
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
        
        serialPrintWithDelay("\n[INFO] Camera settings applied:");
        serialPrintWithDelay(String("Resolution: QVGA (320x240)\n"));
        serialPrintWithDelay(String("Quality: 10\n"));
        serialPrintWithDelay(String("Free PSRAM: ") + String(ESP.getFreePsram()) + String(" bytes\n"));
    } else {
        serialPrintWithDelay("[ERROR] Failed to get sensor settings!");
        return false;
    }
    
    // Test Capture.
    serialPrintWithDelay("\nPerforming test capture...");
    camera_fb_t *fb = esp_camera_fb_get();
    if (fb) {
        serialPrintWithDelay("[INFO] Test capture successful!");
        serialPrintWithDelay(String("Image Size: ") + String(fb->len) + String(" bytes\n"));
        serialPrintWithDelay(String("Resolution: ") + String(fb->width) + String("x") + String(fb->height) + String("\n"));
        serialPrintWithDelay(String("Format: ") + String(fb->format) + String(" (0=JPEG)\n"));
        
        // Verify Image Format.
        if (fb->format != PIXFORMAT_JPEG) {
            serialPrintWithDelay("[ERROR] Capture format is not JPEG!");
            esp_camera_fb_return(fb);
            return false;
        }
        
        // Verify Resolution.
        if (fb->width != 320 || fb->height != 240) {
            serialPrintWithDelay(String("[ERROR] Incorrect resolution: ") + String(fb->width) + String("x") + String(fb->height) + String(" (expected 320x240)\n"));
            esp_camera_fb_return(fb);
            return false;
        }
        
        // Return Frame Buffer.
        esp_camera_fb_return(fb);
    } else {
        serialPrintWithDelay("[ERROR] Test capture failed!");
        return false;
    }
    
    serialPrintWithDelay("[SUCCESS] Camera initialization complete!");
    serialPrintWithDelay("======================================\n");
    return true;
}

// -----------------------------------------------------------------------------------------
// Future Functions. (Old Code)
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
  serialPrintWithDelay("Alarm has been sounded.");
  digitalWrite(LEDStrip_Pin, HIGH);
  serialPrintWithDelay("Lights turned on!");
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
    // Attempt to Capture Frame.
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        // If capture fails, send error response.
        server.send(500, "text/plain", "Camera capture failed");
        return;
    }

    // Clear Any Existing Headers.
    server.client().flush();
    
    // Set Required HTTP Headers.
    server.sendHeader("Content-Type", "image/jpeg");  // Specify JPEG format
    server.sendHeader("Access-Control-Allow-Origin", "*");  // Enable CORS
    server.sendHeader("Connection", "close");  // Close connection after sending
    
    // Prepare Response w/ Correct Content Length.
    server.setContentLength(fb->len);
    server.send(200);  // Send success status

    // Get Client Connection & Send Image Data.
    WiFiClient client = server.client();
    client.write(fb->buf, fb->len);
    
    // Clean Up Allocated Memory & Log Success.
    esp_camera_fb_return(fb);
    serialPrintWithDelay("Sent image: " + String(fb->len) + " bytes");
}

// -----------------------------------------------------------------------------------------
// Notify Gadget of Person Detection.
// -----------------------------------------------------------------------------------------

// Communication to Gadget of Way to Access Node's Photo.

void notifyGadget() {
    // Ensure Wi-Fi is Connected.
    if (WiFi.status() != WL_CONNECTED) {
        serialPrintWithDelay("[ERROR] Wi-Fi Disconnected! Cannot send notification.");
        return;
    }

    // Initialize HTTP Client.
    HTTPClient http;

    // Construct URLs.
    String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
    String url = "http://" + String(GADGET_IP) + "/person_detected";
    
    // Log URLs.
    serialPrintWithDelay("\n--- Sending Notification to Gadget ---");
    serialPrintWithDelay("Camera URL: " + cameraUrl);
    serialPrintWithDelay("Gadget URL: " + url);
    
    // Attempt to Begin HTTP Connection.
    if (!http.begin(url)) {
        serialPrintWithDelay("[ERROR] Failed to begin HTTP connection");
        return;
    }
    
    // Add Headers.
    http.addHeader("Content-Type", "application/json");
    
    // Create JSON w/ Camera Information & Timestamp.
    String timestamp = "2025-01-20T12:34:56Z";  // In real implementation, get actual timestamp
    String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\",\"timestamp\":\"" + timestamp + "\"}";
    serialPrintWithDelay("Sending message: " + message);
    
    // Increase Timeout to Allow Network Recovery.
    http.setTimeout(10000);  // 10 seconds
    
    // Send Message.
    int httpCode = http.POST(message);
    serialPrintWithDelay("HTTP Response code: " + String(httpCode));
    
    // Case for Successful Notification.
    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        serialPrintWithDelay("Response received, length: " + String(response.length()) + " bytes");
        
        // Print Response in Chunks.
        printChunked(response);
        serialPrintWithDelay("Notification sent successfully");
    } else {
        // Case for Failed Notification.
        serialPrintWithDelay("[ERROR] Failed to send notification, HTTP error: " + String(httpCode));
        if (httpCode > 0) {
            String response = http.getString();
            serialPrintWithDelay("Error response: " + response);
        }
    }
    
    // End HTTP Connection.
    http.end();
    serialPrintWithDelay("--- Notification Process Completed ---");
}

// -----------------------------------------------------------------------------------------
// Trigger Alarm.
// -----------------------------------------------------------------------------------------

void handleTriggerAlarm() {
    serialPrintWithDelay("\n========== TRIGGER ALARM REQUEST ==========");
    serialPrintWithDelay("Time: " + String(millis()));
    serialPrintWithDelay("Client IP: " + server.client().remoteIP().toString());
    serialPrintWithDelay("HTTP Method: " + server.method());
    serialPrintWithDelay("URI: " + server.uri());
    
    // Print Request Headers.
    serialPrintWithDelay("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        serialPrintWithDelay(server.headerName(i) + ": " + server.header(i));
    }
    
    // Activate Alarm.
    alarmActive = true;
    digitalWrite(Alarm_Pin, HIGH);
    digitalWrite(TestLED1_Pin, HIGH);

    delay(200);  // Small delay to ensure the alarm gets triggered
    
    // Send detailed response
    String response = "{\"status\":\"alarm_triggered\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    serialPrintWithDelay("\nResponse sent: " + response);
    serialPrintWithDelay("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Turn Off Alarm.
// -----------------------------------------------------------------------------------------

void handleTurnOffAlarm() {
    serialPrintWithDelay("\n========== TURN OFF ALARM REQUEST ==========");
    serialPrintWithDelay("Time: " + String(millis()));
    serialPrintWithDelay("Client IP: " + server.client().remoteIP().toString());
    serialPrintWithDelay("HTTP Method: " + server.method());
    serialPrintWithDelay("URI: " + server.uri());
    
    // Print Request Headers.
    serialPrintWithDelay("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        serialPrintWithDelay(server.headerName(i) + ": " + server.header(i));
    }
    
    // Deactivate Alarm.
    alarmActive = false;
    digitalWrite(Alarm_Pin, LOW);
    digitalWrite(TestLED1_Pin, LOW);

    delay(200);  // Small delay to ensure the alarm gets triggered
    
    // Send Detailed Response.
    String response = "{\"status\":\"alarm_deactivated\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    serialPrintWithDelay("\nResponse sent: " + response);
    serialPrintWithDelay("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Turn On Lights.
// -----------------------------------------------------------------------------------------

void handleTurnOnLights() {
    // Print Detailed Request Information.
    serialPrintWithDelay("\n========== TURN ON LIGHTS REQUEST ==========");
    serialPrintWithDelay("Time: " + String(millis()));
    serialPrintWithDelay("Client IP: " + server.client().remoteIP().toString());
    serialPrintWithDelay("HTTP Method: " + server.method());
    serialPrintWithDelay("URI: " + server.uri());
    
    // Print Request Headers.
    serialPrintWithDelay("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        serialPrintWithDelay(server.headerName(i) + ": " + server.header(i));
    }
    
    // Activate Lights.
    lightsActive = true;
    digitalWrite(LEDStrip_Pin, HIGH);
    //digitalWrite(whitePin, HIGH);

    delay(200);  // Small delay to ensure the lights get activated
    
    // Send Detailed Response.
    String response = "{\"status\":\"lights_activated\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    serialPrintWithDelay("\nResponse sent: " + response);
    serialPrintWithDelay("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Turn Off Lights.
// -----------------------------------------------------------------------------------------

void handleTurnOffLights() {
    // Print Detailed Request Information.
    serialPrintWithDelay("\n========== TURN OFF LIGHTS REQUEST ==========");
    serialPrintWithDelay("Time: " + String(millis()));
    serialPrintWithDelay("Client IP: " + server.client().remoteIP().toString());
    serialPrintWithDelay("HTTP Method: " + server.method());
    serialPrintWithDelay("URI: " + server.uri());
    
    // Print Request Headers.
    serialPrintWithDelay("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) {
        serialPrintWithDelay(server.headerName(i) + ": " + server.header(i));
    }
    
    // Deactivate Lights.
    lightsActive = false;
    digitalWrite(LEDStrip_Pin, LOW);
    //digitalWrite(whitePin, LOW);

    delay(200);  // Small delay to ensure the lights get deactivated
    
    // Send Detailed Response.
    String response = "{\"status\":\"lights_deactivated\",\"timestamp\":\"" + String(millis()) + "\"}";
    server.send(200, "application/json", response);
    serialPrintWithDelay("\nResponse sent: " + response);
    serialPrintWithDelay("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Heartbeat.
// -----------------------------------------------------------------------------------------

void handleHeartbeat() {
    serialPrintWithDelay("\n========== HEARTBEAT REQUEST ==========");
    serialPrintWithDelay("Time: " + String(millis()));
    serialPrintWithDelay("Client IP: " + server.client().remoteIP().toString());
    
    // Reset Missed Heart Beats Counter.
    missedHeartbeats = 0;
    
    // Create Status JSON.
    String response = "{";
    response += "\"status\":\"alive\",";
    response += "\"uptime\":" + String(millis()) + ",";
    response += "\"alarm_active\":" + String(alarmActive ? "true" : "false") + ",";
    response += "\"lights_active\":" + String(lightsActive ? "true" : "false") + ",";
    response += "\"motion_detected\":" + String(motionDetected ? "true" : "false");
    response += "}";
    
    // Send Response.
    server.send(200, "application/json", response);
    serialPrintWithDelay("Heartbeat response sent");
    serialPrintWithDelay("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Set Up Function.
// -----------------------------------------------------------------------------------------

// Main Setup Function.
// Called Upon Power Up or Reset.

void setup()
{
    // Initialize Serial Communication w/ Larger Buffer & Lower Baud Rate.

    Serial.begin(57600);  // Reduced Baud Rate for Better Stability.
    delay(100);  // Give Serial Time to Initialize.

    serialPrintWithDelay("\n--------------------------------");
    serialPrintWithDelay("Starting ESP32-CAM...");
    serialPrintWithDelay("--------------------------------");

    // Initialize Camera w/ Retries.
    bool cameraInitialized = false;
    for (int attempt = 0; attempt < 3 && !cameraInitialized; attempt++) {
        if (attempt > 0) {
            serialPrintWithDelay("\nRetrying camera initialization (attempt " + String(attempt + 1) + "/3)...");
            delay(1000);
        }
        cameraInitialized = initCamera();
    }

    if (!cameraInitialized) {
        serialPrintWithDelay("\n[FATAL] Failed to initialize camera after multiple attempts!");
        serialPrintWithDelay("Please check power supply and camera hardware.");
        serialPrintWithDelay("Restarting in 5 seconds...");
        delay(5000);
        ESP.restart();
    }

    // Wi-Fi Configuration.
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    // Wait for Wi-Fi Connection.
    int attempts = 0;
    serialPrintWithDelay("\nConnecting to WiFi", false);
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {  // 20-second timeout
        delay(1000);
        Serial.print(".");
        Serial.flush();
        attempts++;
    }
    serialPrintWithDelay("");  // New line after dots

    if (WiFi.status() == WL_CONNECTED) {
        serialPrintWithDelay("\nWi-Fi connected successfully!");
        serialPrintWithDelay("ESP32-CAM IP Address: " + WiFi.localIP().toString());
    } else {
        serialPrintWithDelay("\n[ERROR] Wi-Fi connection failed! Restarting...");
        delay(5000);
        ESP.restart();
    }

    // Set up HTTP server endpoints with minimal logging
    server.on("/", HTTP_GET, handleRoot);
    server.on("/capture", HTTP_GET, handleCapture);
    server.on("/trigger_alarm", HTTP_GET, handleTriggerAlarm);
    server.on("/turn_off_alarm", HTTP_GET, handleTurnOffAlarm);
    server.on("/turn_on_lights", HTTP_GET, handleTurnOnLights);
    server.on("/turn_off_lights", HTTP_GET, handleTurnOffLights);
    server.on("/heartbeat", HTTP_GET, handleHeartbeat);
    
    server.onNotFound([]() {
        serialPrintWithDelay("404: " + server.uri());
    });
    
    // Start HTTP Server.
    server.begin();
    serialPrintWithDelay("HTTP server started");

    if (WiFi.status() == WL_CONNECTED) {
        serialPrintWithDelay("\nRegistering with gadget...");
        registerWithGadget();
    }

    initializeHardware();
}

// -----------------------------------------------------------------------------------------
// Register w/ Gadget.
// -----------------------------------------------------------------------------------------

void registerWithGadget() {
    // Initialize HTTP Client.
    HTTPClient http;

    // Construct URLs.
    String cameraUrl = "http://" + WiFi.localIP().toString() + "/capture";
    String url = "http://" + String(GADGET_IP) + "/person_detected";
    
    serialPrintWithDelay("\n--- Starting Registration Process ---");
    serialPrintWithDelay("Camera URL: " + cameraUrl);
    serialPrintWithDelay("Gadget URL: " + url);
    
    if (!http.begin(url)) {
        serialPrintWithDelay("[ERROR] Failed to begin HTTP connection");
        return;
    }

    // Add Headers.
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(10000);

    // Create JSON Message.
    String message = "{\"camera_url\":\"" + cameraUrl + "\",\"node\":\"camera_node1\"}";
    serialPrintWithDelay("Sending registration data...");
    
    // Send Message.
    int httpCode = http.POST(message);
    serialPrintWithDelay("HTTP Response code: " + String(httpCode));
    
    // Case for Successful Registration.
    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        serialPrintWithDelay("Registration successful!");
        serialPrintWithDelay("Response length: " + String(response.length()) + " bytes");
        
        // Print Response in Smaller Chunks w/ Delays.
        const int chunkSize = 64;  // Reduced chunk size.
        serialPrintWithDelay("Response content:");
        printChunked(response);
    } else {
        serialPrintWithDelay("[ERROR] Registration failed, code: " + String(httpCode));
        // Try a Few More Times if Failed.
        for(int i = 0; i < 3 && httpCode != HTTP_CODE_OK; i++) {
            delay(1000);
            serialPrintWithDelay("Retry attempt " + String(i + 1) + "...");
            httpCode = http.POST(message);
            if(httpCode == HTTP_CODE_OK) {
                serialPrintWithDelay("Registration successful on retry!");
                break;
            }
        }
    }
    
    http.end();
    serialPrintWithDelay("--- Registration Process Completed ---");
}

// -----------------------------------------------------------------------------------------
// WiFi Connection Check.
// -----------------------------------------------------------------------------------------

void checkWiFiConnection() {
    // Check WiFi Connection.
    if (WiFi.status() != WL_CONNECTED) {
        serialPrintWithDelay("[WARNING] Wi-Fi lost! Attempting to reconnect...");
        
        // Disconnect and reconnect.
        WiFi.disconnect();
        WiFi.reconnect();
        
        // Attempt to reconnect.
        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 20) {
            delay(1000);
            Serial.print(".");
            attempts++;
        }

        // Case for Successful Reconnection.
        if (WiFi.status() == WL_CONNECTED) {
            serialPrintWithDelay("\nWi-Fi reconnected successfully!");
        serialPrintWithDelay("ESP32-CAM IP Address: " + WiFi.localIP().toString());
        } else {
            serialPrintWithDelay("\n[ERROR] Failed to reconnect. Restarting...");
            delay(5000);
            ESP.restart();
        }
    }
}

// -----------------------------------------------------------------------------------------
// Test Person Detection (For Mobile App Testing)
// -----------------------------------------------------------------------------------------

void simulatePersonDetection() {
    // Set Interval for Testing.
    static unsigned long lastTestDetection = 0;
    const unsigned long TEST_INTERVAL = 30000; // 30 second interval
    
    // Check if it's time to test.
    if (millis() - lastTestDetection >= TEST_INTERVAL) {
        lastTestDetection = millis();
        serialPrintWithDelay("\n[TEST] Simulating person detection...");
        
            // Simulate Motion Detection.
        motionDetected = true;
        
        // Capture Test Image.
        camera_fb_t *fb = esp_camera_fb_get();
        if (!fb) {
            serialPrintWithDelay("[TEST] Camera capture failed");
        } else {
            serialPrintWithDelay("[TEST] Image captured successfully");
            serialPrintWithDelay(String("[TEST] Image size: ") + String(fb->len) + String(" bytes\n"));
            
            // Notify gadget
            notifyGadget();
            
            // Return the frame buffer
            esp_camera_fb_return(fb);
            
            serialPrintWithDelay("[TEST] Test detection notification sent");
        }
        
        // Reset Motion Detection.
        delay(1000);  // Keep motion detected true briefly for status checks
        motionDetected = false;
    }
}

// *********** HARD WARE TESTING ***********
// - Uncomment code below in checkMotionSensor() & initializeHardware() to test hardware.
// - Comment out simulatePersonDetection() to test hardware. 

// -----------------------------------------------------------------------------------------
// Edge Impulse Image Processing.
// -----------------------------------------------------------------------------------------

static int ei_camera_get_data(size_t offset, size_t length, float *out_ptr)
{
    // we already have a RGB888 buffer, so recalculate offset into pixel index
    size_t pixel_ix = offset * 3;
    size_t pixels_left = length;
    size_t out_ptr_ix = 0;

    while (pixels_left != 0) {
        // Swap BGR to RGB here
        // due to https://github.com/espressif/esp32-camera/issues/379
        out_ptr[out_ptr_ix] = (snapshot_buf[pixel_ix + 2] << 16) + (snapshot_buf[pixel_ix + 1] << 8) + snapshot_buf[pixel_ix];

        // go to the next pixel
        out_ptr_ix++;
        pixel_ix+=3;
        pixels_left--;
    }
    // and done!
    return 0;
}
// -----------------------------------------------------------------------------------------
// Process Image with Edge Impulse Model.
// -----------------------------------------------------------------------------------------

bool processImage() {

    Serial.println("[INFO] Capturing Image for Edge Impulse Processing...");

    // Capture Image.
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("[ERROR] Camera capture failed");
        return false;
    }

    // Allocate Buffer for Processing.
    uint8_t * snapshot_buf = (uint8_t *)malloc(EI_CLASSIFIER_INPUT_WIDTH * EI_CLASSIFIER_INPUT_HEIGHT * 3);
    if (!snapshot_buf) {
        Serial.println("[ERROR] Failed to allocate buffer for image processing");
        esp_camera_fb_return(fb);
        return false;
    }  

    // Convert Image to RGB888.
    bool converted = fmt2rgb888(fb->buf, fb->len, PIXFORMAT_JPEG, snapshot_buf);
    esp_camera_fb_return(fb);

    if (!converted) {
        Serial.println("[ERROR] Image conversion failed!");
        free(snapshot_buf);
        return false;
    }

    // Initialize Signal.
    ei::signal_t signal;
    signal.total_length = EI_CLASSIFIER_INPUT_WIDTH * EI_CLASSIFIER_INPUT_HEIGHT;
    signal.get_data = &ei_camera_get_data;

    // Run Classifier.
    ei_impulse_result_t result = { 0 };
    EI_IMPULSE_ERROR err = run_classifier(&signal, &result, false);

    // Check for Errors.
    if(err != EI_IMPULSE_OK) {
        Serial.println("[ERROR] Failed to run classifier");
        free(snapshot_buf);
        return false;
    }

    // Check for Person Detection.
    bool personDetected = false;
    for (uint16_t i = 0; i < EI_CLASSIFIER_LABEL_COUNT; i++) {
        if (strcmp(ei_classifier_inferencing_categories[i], "person") == 0 && result.classification[i].value > 0.7) {
            personDetected = true;
        }
    }

    // Free Buffer.
    free(snapshot_buf);
    esp_camera_fb_return(fb);

    return personDetected;
}

// Check Motion Sensor.
// -----------------------------------------------------------------------------------------

void checkMotionSensor() {
    // Check motion sensor at regular intervals.

    if (millis() - lastMotionCheck >= MOTION_CHECK_INTERVAL) {
        lastMotionCheck = millis();
        
        // Read PIR sensor.
        int pirValue = digitalRead(PassiveIR_Pin);
        if (pirValue == HIGH) {
            Serial.println("\n[MOTION] PIR sensor detected motion.");
            
            // Capture Image.
            if (processImage()) {
                Serial.println("[DETECTION] Person detected in image!!!!");
                notifyGadget();
            } else {
                Serial.println("[INFO] No person detected in image.");
            }
        } else {
            Serial.println("[INFO] No motion detected.");
        }
            
    }
}

// -----------------------------------------------------------------------------------------
// Initialize Hardware.
// -----------------------------------------------------------------------------------------

void initializeHardware() {
    serialPrintWithDelay("\n========== INITIALIZING HARDWARE ==========");
    /*
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
    */
    // Print notification.
    serialPrintWithDelay("PIR sensors initialized");
    serialPrintWithDelay("Output devices initialized");
    serialPrintWithDelay("=========================================\n");
}

// -----------------------------------------------------------------------------------------
// Main Loop.
// -----------------------------------------------------------------------------------------

// After Setup, Main Loop Continues to Run actively processing requests.

void loop()
{
    // 1. Check Wi-Fi Connection & Reconnect if Disconnected.
    static unsigned long lastWiFiCheck = 0;
    const unsigned long WIFI_CHECK_INTERVAL = 10000; // Check every 10 seconds
    
    if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) {
        lastWiFiCheck = millis();
        checkWiFiConnection();
    }

    // 2. Handle Incoming HTTP Requests w/ Status Indicator.
    static unsigned long lastRequestTime = 0;
    static bool isHandlingRequest = false;
    
    if (server.client()) {
        if (!isHandlingRequest) {
            isHandlingRequest = true;
            lastRequestTime = millis();
            digitalWrite(RedLED_Pin, HIGH); // Visual indicator that we're handling a request
        }
    }
    
    // Handle Incoming Requests.
    server.handleClient();
    
    // Reset LED after request.
    if (isHandlingRequest && millis() - lastRequestTime > 100) {
        isHandlingRequest = false;
        digitalWrite(RedLED_Pin, LOW);
    }
    
    // 3. Check Motion Sensor at Regular Intervals.
    checkMotionSensor();
    
    // 4. Check Heartbeat.
    if (millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) {
        lastHeartbeat = millis();
        missedHeartbeats++;
        
        if (missedHeartbeats >= MAX_MISSED_HEARTBEATS) {
            serialPrintWithDelay("[WARNING] Multiple heartbeats missed. Checking WiFi connection...");
            checkWiFiConnection();
        }
    }
    
    // 5. Handle Alarm State.
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