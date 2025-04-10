// --------
// INCLUDES
// --------

#include <Person_detector_x2_inferencing.h>     // Header for Edge impulse project.
#include "edge-impulse-sdk/dsp/image/image.hpp" // Provides Image processing functions.
#include "esp_camera.h"                         // Manages Camera Initialization.
#include <WiFi.h>                               // Manages WiFi connectivity.
#include <HTTPClient.h>                         // Enables HTTP Communication.
#include <WebServer.h>
#include "esp_task_wdt.h"

// Web Server.
WebServer server(80);

// WiFi Credentials.
const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";

// -------------------
// GADGET IP ADDRESSES
// -------------------

// Dev Board.
const char* GADGET_IP = "192.168.8.151";

// Real Board.
// const char* GADGET_IP = "192.168.8.207";

// ---------
// CONSTANTS
// ---------

const int PassiveIR_Pin         = 12;  // Passive IR sensor pin.
const int LEDStrip_Pin          = 14;  // LED STRIP PIN
const int Alarm_Pin             = 13;  // ALARM PIN
const int PersonDetected_Pin    = 16;  // Person Detected Pin.

// -------
// DEFINES
// -------

// #define CAMERA_MODEL_ESP_EYE // Has PSRAM
#define CAMERA_MODEL_AI_THINKER // Has PSRAM

#if defined(CAMERA_MODEL_ESP_EYE)
#define PWDN_GPIO_NUM    -1
#define RESET_GPIO_NUM   -1
#define XCLK_GPIO_NUM    4
#define SIOD_GPIO_NUM    18
#define SIOC_GPIO_NUM    23

#define Y9_GPIO_NUM      36
#define Y8_GPIO_NUM      37
#define Y7_GPIO_NUM      38
#define Y6_GPIO_NUM      39
#define Y5_GPIO_NUM      35
#define Y4_GPIO_NUM      14
#define Y3_GPIO_NUM      13
#define Y2_GPIO_NUM      34
#define VSYNC_GPIO_NUM   5
#define HREF_GPIO_NUM    27
#define PCLK_GPIO_NUM    25

#elif defined(CAMERA_MODEL_AI_THINKER)
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

#else
#error "Camera model not selected"
#endif

// Constant defines
#define EI_CAMERA_RAW_FRAME_BUFFER_COLS           320 // Potentially change to 96x96
#define EI_CAMERA_RAW_FRAME_BUFFER_ROWS           240
#define EI_CAMERA_FRAME_BYTE_SIZE                 3

// Private variables
static bool debug_nn = false;     // Set this to true to see e.g. features generated from the raw signal
static bool is_initialised = false;
uint8_t *snapshot_buf;            // points to the output of the capture

// Hardware state variables.
bool alarmActive = false;
bool lightsActive = false;
bool motionDetected = false;
// unsigned long lastMotionCheck = 0;
// const unsigned long MOTION_CHECK_INTERVAL = 500; // Check motion every 500ms

// Heartbeat variables.
unsigned long lastHeartbeat = 0;
const unsigned long HEARTBEAT_INTERVAL = 30000; // Send heartbeat every 30 seconds
const int MAX_MISSED_HEARTBEATS = 5;
int missedHeartbeats = 0;

// Helper functions.
void serialPrintWithDelay(const String& message, bool newLine = true, int delayMs = 10) 
{
    if (newLine) 
    {
        Serial.println(message);
    } 
    
    else 
    {
        Serial.print(message);
    }

    Serial.flush();
    delay(delayMs);  // Allow time for the buffer to clear
}

void printChunked(const String& message, int chunkSize = 32) 
{
    for (size_t i = 0; i < message.length(); i += chunkSize) 
    {
        String chunk = message.substring(i, min(i + chunkSize, message.length()));
        serialPrintWithDelay(chunk, false, 5);
    }

    serialPrintWithDelay("", true, 10);  // Final newline
}

void checkWiFiConnection() 
{
    // Check WiFi Connection.
    if (WiFi.status() != WL_CONNECTED) 
    {
        serialPrintWithDelay("[WARNING] Wi-Fi lost! Attempting to reconnect...");
        
        // Disconnect and reconnect.
        WiFi.disconnect();
        WiFi.reconnect();
        
        // Attempt to reconnect.
        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 20) 
        {
            delay(1000);
            Serial.print(".");
            attempts++;
        }

        // Case for Successful Reconnection.
        if (WiFi.status() == WL_CONNECTED) 
        {
            serialPrintWithDelay("\nWi-Fi reconnected successfully!");
            serialPrintWithDelay("ESP32-CAM IP Address: " + WiFi.localIP().toString());
        } 
        
        else 
        {
            serialPrintWithDelay("\n[ERROR] Failed to reconnect. Restarting...");
            delay(5000);
            ESP.restart();
        }
    }
}

// Configure camera with optimized settings
static camera_config_t camera_config = 
{
    .pin_pwdn = PWDN_GPIO_NUM,
    .pin_reset = RESET_GPIO_NUM,
    .pin_xclk = XCLK_GPIO_NUM,
    .pin_sscb_sda = SIOD_GPIO_NUM,
    .pin_sscb_scl = SIOC_GPIO_NUM,

    .pin_d7 = Y9_GPIO_NUM,
    .pin_d6 = Y8_GPIO_NUM,
    .pin_d5 = Y7_GPIO_NUM,
    .pin_d4 = Y6_GPIO_NUM,
    .pin_d3 = Y5_GPIO_NUM,
    .pin_d2 = Y4_GPIO_NUM,
    .pin_d1 = Y3_GPIO_NUM,
    .pin_d0 = Y2_GPIO_NUM,
    .pin_vsync = VSYNC_GPIO_NUM,
    .pin_href = HREF_GPIO_NUM,
    .pin_pclk = PCLK_GPIO_NUM,

    .xclk_freq_hz = 10000000,        // Reduced to 10MHz for stability
    .ledc_timer = LEDC_TIMER_0,
    .ledc_channel = LEDC_CHANNEL_0,

    .pixel_format = PIXFORMAT_JPEG,  // Use JPEG for inference to reduce memory usage
    .frame_size = FRAMESIZE_QVGA,    // 320x240 - good balance for person detection
    
    .jpeg_quality = 12,              // Lower quality for faster processing
    .fb_count = 1,                   // Single buffer to avoid sync issues
    .fb_location = CAMERA_FB_IN_PSRAM,
    .grab_mode = CAMERA_GRAB_WHEN_EMPTY // Wait for buffer to be empty before capture
};

// Add camera sensor configuration function
void configureCameraSensor() {
    sensor_t * s = esp_camera_sensor_get();
    if (s) {
        // Adjust sensor settings for better reliability
        s->set_brightness(s, 1);     // Increase brightness slightly
        s->set_contrast(s, 1);       // Default contrast
        s->set_saturation(s, -2);    // Reduce saturation for better detection
        s->set_special_effect(s, 0); // No special effects
        s->set_whitebal(s, 1);       // Enable white balance
        s->set_awb_gain(s, 1);       // Enable auto white balance gain
        s->set_wb_mode(s, 0);        // Auto white balance
        s->set_exposure_ctrl(s, 1);   // Enable auto exposure
        s->set_aec2(s, 0);           // Disable AEC DSP
        s->set_gain_ctrl(s, 1);      // Enable auto gain
        s->set_agc_gain(s, 0);       // Set AGC gain to 0
        s->set_gainceiling(s, (gainceiling_t)6); // Set gain ceiling
        s->set_bpc(s, 1);            // Enable black pixel correction
        s->set_wpc(s, 1);            // Enable white pixel correction
        s->set_raw_gma(s, 1);        // Enable gamma correction
        s->set_lenc(s, 1);           // Enable lens correction
        s->set_hmirror(s, 0);        // No horizontal mirror
        s->set_vflip(s, 0);          // No vertical flip
        s->set_dcw(s, 1);            // Enable downsize crop
        s->set_colorbar(s, 0);       // Disable colorbar test
    }
}

// --------------------
// Function definitions
// --------------------

// De-initializes camera.
void ei_camera_deinit(void);    
// Initializes camera, true if success.
bool ei_camera_init(void);      
// Captures image and stores in buffer.
bool ei_camera_capture(uint32_t img_width, uint32_t img_height, uint8_t *out_buf) ;

// ----
// CODE
// ----

// -----------------------------------------------------------------------------------------
// Handle root endpoint (/)
// -----------------------------------------------------------------------------------------

// Serves as a overall Health Check for the Node.
// Accessed at http://<node-ip>/ should display "ESP32-CAM Node 1".
void handleRoot() 
{
  server.send(200, "text/plain", "ESP32-CAM Node 1");
}

// -----------------------------------------------------------------------------------------
// Handle capture request. (/capture)
// -----------------------------------------------------------------------------------------

// Capturing Photo & Sending Photo Back As HTTP Response.
void handleCapture() 
{
    const int MAX_RETRIES = 3;
    const int CAPTURE_DELAY = 50;  // 50ms delay between retries
    camera_fb_t *fb = nullptr;
    
    // Try multiple times to get a valid frame
    for (int attempt = 0; attempt < MAX_RETRIES; attempt++) {
        if (attempt > 0) {
            delay(CAPTURE_DELAY);  // Add delay between retries
            serialPrintWithDelay("Retry attempt " + String(attempt + 1));
        }
        
        fb = esp_camera_fb_get();
        if (!fb) {
            serialPrintWithDelay("Camera capture failed on attempt " + String(attempt + 1));
            continue;
        }

        // Verify we have a valid JPEG
        if (fb->format != PIXFORMAT_JPEG || fb->len == 0) {
            serialPrintWithDelay("Invalid format or empty buffer");
            esp_camera_fb_return(fb);
            continue;
        }

        // Basic JPEG header validation
        if (fb->len < 100 || fb->buf[0] != 0xFF || fb->buf[1] != 0xD8) {
            serialPrintWithDelay("Invalid JPEG header detected");
            esp_camera_fb_return(fb);
            continue;
        }

        // If we got here, we have a valid frame
        break;
    }

    // If all attempts failed
    if (!fb) {
        server.send(500, "text/plain", "Failed to capture valid image after multiple attempts");
        return;
    }

    // Send headers before heavy processing
    server.client().flush();
    server.sendHeader("Content-Type", "image/jpeg");
    server.sendHeader("Content-Disposition", "inline; filename=capture.jpg");
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.setContentLength(fb->len);
    server.send(200);

    // Stream the JPEG data in chunks with better error handling
    WiFiClient client = server.client();
    const size_t chunk_size = 4096; // 4KB chunks
    size_t remaining = fb->len;
    size_t index = 0;
    bool success = true;

    while (remaining > 0 && client.connected()) {
        size_t chunk = (remaining < chunk_size) ? remaining : chunk_size;
        size_t written = client.write(fb->buf + index, chunk);
        
        if (written == 0) {
            success = false;
            serialPrintWithDelay("Failed to write chunk to client");
            break;
        }
        
        remaining -= written;
        index += written;
        
        // Yield to prevent watchdog triggers
        delay(0);
    }

    // Clean up
    esp_camera_fb_return(fb);

    if (success) {
        serialPrintWithDelay("Image sent successfully: " + String(index) + " bytes");
    } else {
        serialPrintWithDelay("Image transfer failed or incomplete");
    }
}

// -----------------------------------------------------------------------------------------
// Notify Gadget of Person Detection.
// -----------------------------------------------------------------------------------------

// Communication to Gadget of Way to Access Node's Photo.
void notifyGadget() 
{
    // Ensure Wi-Fi is Connected.
    if (WiFi.status() != WL_CONNECTED) 
    {
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
    if (!http.begin(url)) 
    {
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
    if (httpCode == HTTP_CODE_OK) 
    {
        String response = http.getString();
        serialPrintWithDelay("Response received, length: " + String(response.length()) + " bytes");
        
        // Print Response in Chunks.
        printChunked(response);
        serialPrintWithDelay("Notification sent successfully");
    } 
    
    else 
    {
        // Case for Failed Notification.
        serialPrintWithDelay("[ERROR] Failed to send notification, HTTP error: " + String(httpCode));

        if (httpCode > 0) 
        {
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

void handleTriggerAlarm() 
{
    serialPrintWithDelay("\n========== TRIGGER ALARM REQUEST ==========");
    serialPrintWithDelay("Time: " + String(millis()));
    serialPrintWithDelay("Client IP: " + server.client().remoteIP().toString());
    serialPrintWithDelay("HTTP Method: " + server.method());
    serialPrintWithDelay("URI: " + server.uri());
    
    //   Print Request Headers.
    serialPrintWithDelay("\nRequest Headers:");
    for (int i = 0; i < server.headers(); i++) 
    {
        serialPrintWithDelay(server.headerName(i) + ": " + server.header(i));
    }
    
    // Activate Alarm.
    alarmActive = true;
    digitalWrite(Alarm_Pin, HIGH);

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
    digitalWrite(4, HIGH);
    digitalWrite(LEDStrip_Pin, HIGH);
    delay(10000);
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
    digitalWrite(4, LOW);

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

void handleHeartbeat() 
{
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

void registerWithGadget() 
{
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
    if (httpCode == HTTP_CODE_OK) 
    {
        String response = http.getString();
        serialPrintWithDelay("Registration successful!");
        serialPrintWithDelay("Response length: " + String(response.length()) + " bytes");
        
        // Print Response in Smaller Chunks w/ Delays.
        const int chunkSize = 64;  // Reduced chunk size.
        serialPrintWithDelay("Response content:");
        printChunked(response);
    } 
    
    else 
    {
        serialPrintWithDelay("[ERROR] Registration failed, code: " + String(httpCode));

        // Try a Few More Times if Failed.
        for(int i = 0; i < 3 && httpCode != HTTP_CODE_OK; i++) 
        {
            delay(1000);
            serialPrintWithDelay("Retry attempt " + String(i + 1) + "...");
            httpCode = http.POST(message);
            if(httpCode == HTTP_CODE_OK) 
            {
                serialPrintWithDelay("Registration successful on retry!");
                break;
            }
        }
    }
    
    http.end();
    serialPrintWithDelay("--- Registration Process Completed ---");
}

// Main Setup Function.
void setup()
{
    Serial.begin(115200);
    Serial.println("--------------------------------");
    Serial.println("Serial communication starting...");
    Serial.println("--------------------------------");

    // Initialize Passive IR sensor pin
    //pinMode(PassiveIR_Pin, INPUT); // Set PassiveIR_Pin as input
    pinMode(LEDStrip_Pin, OUTPUT);
    pinMode(Alarm_Pin, OUTPUT);
    pinMode(33, OUTPUT);
    pinMode(4, OUTPUT);


    
    // Initialize camera.
    if (ei_camera_init() == false) 
    {
        ei_printf("Failed to initialize Camera!\r\n");
    }

    else 
    {
        ei_printf("Camera initialized\r\n");
    }

    // Configure wifi connection.
    // Disable wifi persistence.
    WiFi.mode(WIFI_STA);  // Wifi to station mode.
    WiFi.begin(WIFI_SSID, WIFI_PASS); // Connect to the wifi network.

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

    if (WiFi.status() == WL_CONNECTED) 
    {
        serialPrintWithDelay("\nWi-Fi connected successfully!");
        serialPrintWithDelay("ESP32-CAM IP Address: " + WiFi.localIP().toString());
    } 
    
    else 
    {
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

    server.onNotFound([]() 
    {
        serialPrintWithDelay("404: " + server.uri());
    });
    
    // Start HTTP Server.
    server.begin();
    serialPrintWithDelay("HTTP server started");

    if (WiFi.status() == WL_CONNECTED) 
    {
        serialPrintWithDelay("\nRegistering with gadget...");
        registerWithGadget();
    }
    
    ei_printf("\nWaiting for Passive IR trigger to start image processing...\n");
}


// Main Loop Function
void loop()
{
  // 1. Check Wi-Fi Connection & Reconnect if Disconnected.
  static unsigned long lastWiFiCheck = 0;
  const unsigned long WIFI_CHECK_INTERVAL = 10000; // Check every 10 seconds
  
  if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) 
  {
      lastWiFiCheck = millis();
      checkWiFiConnection();
  }

  // 2. Handle Incoming HTTP Requests w/ Status Indicator.
  static unsigned long lastRequestTime = 0;
  static bool isHandlingRequest = false;
    
  if (server.client()) 
  {
      if (!isHandlingRequest) 
      {
          isHandlingRequest = true;
          lastRequestTime = millis();
          // digitalWrite(RedLED_Pin, HIGH); // Visual indicator that we're handling a request
      }
  }
    
  // Handle Incoming Requests.
  server.handleClient();
  
  // Reset LED after request.
  if (isHandlingRequest && millis() - lastRequestTime > 100) 
  {
      isHandlingRequest = false;
      // digitalWrite(RedLED_Pin, LOW);
  }

  // 4. Check Heartbeat.
  if (millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) 
  {
      lastHeartbeat = millis();
      missedHeartbeats++;
      
      if (missedHeartbeats >= MAX_MISSED_HEARTBEATS) 
      {
          // serialPrintWithDelay("[WARNING] Multiple heartbeats missed. Checking WiFi connection...");
          checkWiFiConnection();
      }
  }

  char input = Serial.read();

  if (input == 'P')
  {
    Serial.println("Passive IR sensor triggered! Capturing image...");

    // Allocate memory for the snapshot buffer
    snapshot_buf = (uint8_t*)malloc(EI_CAMERA_RAW_FRAME_BUFFER_COLS * EI_CAMERA_RAW_FRAME_BUFFER_ROWS * EI_CAMERA_FRAME_BYTE_SIZE);

    if (snapshot_buf == nullptr) 
    {
        ei_printf("ERR: Failed to allocate snapshot buffer!\n");
        return;
    }

    ei::signal_t signal;
    signal.total_length = EI_CLASSIFIER_INPUT_WIDTH * EI_CLASSIFIER_INPUT_HEIGHT;
    signal.get_data = &ei_camera_get_data;

    // Capture an image
    if (ei_camera_capture((size_t)EI_CLASSIFIER_INPUT_WIDTH, (size_t)EI_CLASSIFIER_INPUT_HEIGHT, snapshot_buf) == false) 
    {
        ei_printf("Failed to capture image\r\n");
        free(snapshot_buf);
        return;
    }

    // Add image quality checks
    bool is_valid_image = true;
    uint32_t dark_pixels = 0;
    uint32_t bright_pixels = 0;
    uint32_t total_pixels = EI_CLASSIFIER_INPUT_WIDTH * EI_CLASSIFIER_INPUT_HEIGHT;

    // Check image isn't too dark or too bright
    for (uint32_t i = 0; i < total_pixels * 3; i += 3) {
        uint8_t r = snapshot_buf[i];
        uint8_t g = snapshot_buf[i + 1];
        uint8_t b = snapshot_buf[i + 2];
        
        // Calculate luminance
        float luminance = 0.299f * r + 0.587f * g + 0.114f * b;
        
        if (luminance < 30) dark_pixels++;      // Too dark threshold
        if (luminance > 220) bright_pixels++;   // Too bright threshold
    }

    // Calculate percentages
    float dark_percent = (float)dark_pixels / total_pixels * 100;
    float bright_percent = (float)bright_pixels / total_pixels * 100;

    // Image quality checks
    if (dark_percent > 80) {
        ei_printf("Image too dark (%.1f%% dark pixels). Skipping inference.\n", dark_percent);
        free(snapshot_buf);
        return;
    }
    if (bright_percent > 80) {
        ei_printf("Image too bright (%.1f%% bright pixels). Skipping inference.\n", bright_percent);
        free(snapshot_buf);
        return;
    }

    // Run the classifier
    ei_impulse_result_t result = { 0 };
    EI_IMPULSE_ERROR err = run_classifier(&signal, &result, debug_nn);
    if (err != EI_IMPULSE_OK) 
    {
        ei_printf("ERR: Failed to run classifier (%d)\n", err);
        free(snapshot_buf);
        return;
    }

    // print the predictions
    ei_printf("Predictions (DSP: %d ms., Classification: %d ms., Anomaly: %d ms.): \n",
                result.timing.dsp, result.timing.classification, result.timing.anomaly);

    // Process the classifier results with confidence threshold
    bool personDetected = false;
    float confidence_threshold = 0.4; // Adjust this threshold as needed (0.0 to 1.0)

#if EI_CLASSIFIER_OBJECT_DETECTION == 1
    ei_printf("Object detection bounding boxes:\r\n");
    for (uint32_t i = 0; i < result.bounding_boxes_count; i++) 
    {
        ei_impulse_result_bounding_box_t bb = result.bounding_boxes[i];
        if (bb.value < confidence_threshold) {
            ei_printf("  %s (%.2f) - Below confidence threshold, ignoring\n", bb.label, bb.value);
            continue;
        }
        ei_printf("  %s (%.2f) [ x: %u, y: %u, width: %u, height: %u ]\r\n",
                bb.label,
                bb.value,
                bb.x,
                bb.y,
                bb.width,
                bb.height);
        personDetected = true;
    }

    // Print the prediction results (classification)
#else
    ei_printf("Predictions:\r\n");
    for (uint16_t i = 0; i < EI_CLASSIFIER_LABEL_COUNT; i++) 
    {
        ei_printf("  %s: ", ei_classifier_inferencing_categories[i]);
        ei_printf("%.5f\r\n", result.classification[i].value);
    }
#endif

    if (personDetected) 
    {
        notifyGadget();

        Serial.println("[INFO] Person detected in the image.");
        Serial.println("[INFO] Turning on lights...");

        digitalWrite(LEDStrip_Pin, HIGH);
        digitalWrite(Alarm_Pin, HIGH);

        Serial.println("[INFO] Triggering alarm...");
        Serial.println("[INFO] Sending notification to gadget...");

        delay(15000); // 15 seconds.

        digitalWrite(LEDStrip_Pin, LOW);
        digitalWrite(Alarm_Pin, LOW);

        Serial.println("[INFO] Alarm turned off.");
        Serial.println("[INFO] Lights turned off.");

        delay(2000);
    } 
    else 
    {
        Serial.println("[INFO] No person detected in the image.");
    }

    free(snapshot_buf);
  }

  delay(3000); // Small delay to avoid rapid polling
}

/**
 * @brief   Setup image sensor & start streaming
 *
 * @retval  false if initialisation failed
 */
bool ei_camera_init(void) {
    if (is_initialised) return true;

#if defined(CAMERA_MODEL_ESP_EYE)
    pinMode(13, INPUT_PULLUP);
    pinMode(14, INPUT_PULLUP);
#endif

    // Initialize the camera
    esp_err_t err = esp_camera_init(&camera_config);
    if (err != ESP_OK) {
        ei_printf("Camera init failed with error 0x%x\n", err);
        return false;
    }

    // Configure additional sensor settings
    configureCameraSensor();

    is_initialised = true;
    return true;
}

/**
 * @brief      Stop streaming of sensor data
 */
void ei_camera_deinit(void) {

    //deinitialize the camera
    esp_err_t err = esp_camera_deinit();

    if (err != ESP_OK)
    {
        ei_printf("Camera deinit failed\n");
        return;
    }

    is_initialised = false;
    return;
}


/**
 * @brief      Capture, rescale and crop image
 *
 * @param[in]  img_width     width of output image
 * @param[in]  img_height    height of output image
 * @param[in]  out_buf       pointer to store output image, NULL may be used
 *                           if ei_camera_frame_buffer is to be used for capture and resize/cropping.
 *
 * @retval     false if not initialised, image captured, rescaled or cropped failed
 *
 */
bool ei_camera_capture(uint32_t img_width, uint32_t img_height, uint8_t *out_buf) {
    const int STABILIZATION_DELAY = 50;  // ms to wait between captures
    const int MAX_RETRIES = 3;
    
    if (!is_initialised) {
        ei_printf("ERR: Camera is not initialized\r\n");
        return false;
    }

    // Try multiple times to get a valid frame
    for (int attempt = 0; attempt < MAX_RETRIES; attempt++) {
        if (attempt > 0) {
            ei_printf("Retrying capture, attempt %d of %d\n", attempt + 1, MAX_RETRIES);
            delay(STABILIZATION_DELAY);  // Wait before retry
        }

        camera_fb_t *fb = esp_camera_fb_get();
        if (!fb) {
            ei_printf("Camera capture failed on attempt %d\n", attempt + 1);
            continue;
        }

        // Verify we have valid data
        if (fb->len == 0 || fb->buf == nullptr) {
            ei_printf("Invalid frame buffer\n");
            esp_camera_fb_return(fb);
            continue;
        }

        bool success = false;
        if (fb->format == PIXFORMAT_JPEG) {
            success = fmt2rgb888(fb->buf, fb->len, PIXFORMAT_JPEG, out_buf);
        } else {
            memcpy(out_buf, fb->buf, fb->len);
            success = true;
        }

        esp_camera_fb_return(fb);

        if (!success) {
            ei_printf("Format conversion failed\n");
            continue;
        }

        // If we need to resize
        if ((img_width != EI_CAMERA_RAW_FRAME_BUFFER_COLS) || 
            (img_height != EI_CAMERA_RAW_FRAME_BUFFER_ROWS)) {
            ei::image::processing::crop_and_interpolate_rgb888(
                out_buf,
                EI_CAMERA_RAW_FRAME_BUFFER_COLS,
                EI_CAMERA_RAW_FRAME_BUFFER_ROWS,
                out_buf,
                img_width,
                img_height
            );
        }

        return true;  // Successfully captured and processed
    }

    return false;  // Failed after all retries
}

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

#if !defined(EI_CLASSIFIER_SENSOR) || EI_CLASSIFIER_SENSOR != EI_CLASSIFIER_SENSOR_CAMERA
#error "Invalid model for current sensor"
#endif


// -----------------------------------------------------------------
//                           main.ino(node)
// -----------------------------------------------------------------.