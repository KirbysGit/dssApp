// -----------------------------------------------------------------------------------------
// INCLUDES.
// -----------------------------------------------------------------------------------------

#include <Person_detector_x2_inferencing.h>     // Header for Edge impulse project.
#include "edge-impulse-sdk/dsp/image/image.hpp" // Provides Image processing functions.
#include "esp_camera.h"                         // Manages Camera Initialization.
#include <WiFi.h>                               // Manages WiFi connectivity.
#include <HTTPClient.h>                         // Enables HTTP Communication.
#include <WebServer.h>                          // Manages Web Server.
#include <esp32cam.h>                           // Manages Camera Initialization.
#include <esp_heap_caps.h>                      // Manages Heap Memory.
#include "base64.h"                             // Manages Base64 Encoding.

// -----------------------------------------------------------------------------------------
// DEFINES.
// -----------------------------------------------------------------------------------------

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

#define EI_CAMERA_RAW_FRAME_BUFFER_COLS           320
#define EI_CAMERA_RAW_FRAME_BUFFER_ROWS           240
#define EI_CAMERA_FRAME_BYTE_SIZE                 3

// -----------------------------------------------------------------------------------------
// PINS.
// -----------------------------------------------------------------------------------------

// Passive IR sensor pin.
const byte PassiveIR_Pin = GPIO_NUM_12;

// Active IR sensor pin #1.
const byte ActiveIR1_Pin = GPIO_NUM_14;

// Active IR sensor pin #2.
const byte ActiveIR2_Pin = GPIO_NUM_13;

// White LED Strip.
const byte LEDStrip_Pin = GPIO_NUM_15;

// Alarm (Buzzer).
const byte Alarm_Pin = GPIO_NUM_13;

// Test LED #1.
const byte RedLED_Pin = GPIO_NUM_2;

// Test LED #2.
const byte WhiteLED_Pin = GPIO_NUM_16;

// Chip Enable.
const byte ChipEnable_Pin = GPIO_NUM_0;

// -----------------------------------------------------------------------------------------
// CONSTANTS.
// -----------------------------------------------------------------------------------------

// Hardware state variables.        
bool alarmActive = false;                         // Indicates if the alarm is active.
bool lightsActive = false;                        // Indicates if the lights are active.
bool motionDetected = false;                      // Indicates if motion has been detected.
bool personDetected = false;                      // Indicates if a person has been detected.
bool cameraInitialized = false;                   // Indicates if the camera is initialised.
unsigned long lastMotionCheck = 0;                // Last motion check timestamp.
const unsigned long MOTION_CHECK_INTERVAL = 500;  // Check motion every 500ms

// Heartbeat variables.
unsigned long lastHeartbeat = 0;                 // Last heartbeat timestamp.
const unsigned long HEARTBEAT_INTERVAL = 30000;  // Send heartbeat every 30 seconds
const int MAX_MISSED_HEARTBEATS = 5;             // Maximum number of missed heartbeats.
int missedHeartbeats = 0;                        // Number of missed heartbeats.

// Private variables
static bool debug_nn = false;                    // Set this to true to see e.g. features generated from the raw signal
static bool is_initialised = false;              // Indicates if the camera is initialized.
uint8_t *snapshot_buf;                           // points to the output of the capture

// -----------------------------------------------------------------------------------------
// WIFI CONFIG.
// -----------------------------------------------------------------------------------------

// Microrouter Network.
const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";
const char* GADGET_IP = "192.168.8.151";

// Kirby's Hotspot.
/*
const char* WIFI_SSID = "mi telefono";
const char* WIFI_PASS = "password";
const char* GADGET_IP = "172.20.10.8";
*/

// -----------------------------------------------------------------------------------------
// WEB SERVER.
// -----------------------------------------------------------------------------------------

WebServer server(80);

// -----------------------------------------------------------------------------------------
// CAMERA CONFIG.
// -----------------------------------------------------------------------------------------

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

    //XCLK 20MHz or 10MHz for OV2640 double FPS (Experimental)
    .xclk_freq_hz = 20000000,       // Set Clock speed (20Mhz)
    .ledc_timer = LEDC_TIMER_0,
    .ledc_channel = LEDC_CHANNEL_0,

    .pixel_format = PIXFORMAT_JPEG, // Use JPEG for Pixel Format
    .frame_size = FRAMESIZE_QVGA,    //QQVGA-UXGA Do not use sizes above QVGA when not JPEG

    .jpeg_quality = 12, //0-63 lower number means higher quality
    .fb_count = 1,       //if more than one, i2s runs in continuous mode. Use only with JPEG
    .fb_location = CAMERA_FB_IN_PSRAM,
    .grab_mode = CAMERA_GRAB_WHEN_EMPTY,
};

// -----------------------------------------------------------------------------------------
// FUNCTION DEFINITIONS.
// -----------------------------------------------------------------------------------------

// De-initializes camera.
void ei_camera_deinit(void);

// Initializes camera, true if success.
bool ei_camera_init(void);

// Captures image and stores in buffer.
bool ei_camera_capture(uint32_t img_width, uint32_t img_height, uint8_t *out_buf) ;

// -----------------------------------------------------------------------------------------
// HELPER FUNCTIONS.
// -----------------------------------------------------------------------------------------

// * NOTE : Added for sake of not overwloading the serial buffer.

// Prints message to serial with delay.
void serialPrintWithDelay(const String& message, bool newLine = true, int delayMs = 10) {
    if (newLine) {
        Serial.println(message);
    } else {
        Serial.print(message);
    }
    Serial.flush();
    delay(delayMs);  // Allow time for the buffer to clear
}

// -----------------------------------------------------

// Prints message to serial in chunks.
void printChunked(const String& message, int chunkSize = 32) {
    for (size_t i = 0; i < message.length(); i += chunkSize) {
        String chunk = message.substring(i, min(i + chunkSize, message.length()));
        serialPrintWithDelay(chunk, false, 5);
    }
    serialPrintWithDelay("", true, 10);  // Final newline
}

// -----------------------------------------------------------------------------------------
// CODE.
// -----------------------------------------------------------------------------------------

// -----------------------------------------------------------------------------------------
// CAMERA INITIALIZATION.
// -----------------------------------------------------------------------------------------

/**
 * @brief   Setup image sensor & start streaming
 *
 * @retval  false if initialisation failed
 */
bool ei_camera_init(void) 
{

    if (is_initialised) return true;

    #if defined(CAMERA_MODEL_ESP_EYE)
        pinMode(13, INPUT_PULLUP);
        pinMode(14, INPUT_PULLUP);
    #endif

    // Initialize the camera.
    esp_err_t err = esp_camera_init(&camera_config);
    if (err != ESP_OK) {
      Serial.printf("Camera init failed with error 0x%x\n", err);
      return false;
    }

    sensor_t * s = esp_camera_sensor_get();
    // initial sensors are flipped vertically and colors are a bit saturated
    if (s->id.PID == OV3660_PID) {
      s->set_vflip(s, 1); // flip it back
      s->set_brightness(s, 1); // up the brightness just a bit
      s->set_saturation(s, 0); // lower the saturation
    }

    #if defined(CAMERA_MODEL_M5STACK_WIDE)
        s->set_vflip(s, 1);
        s->set_hmirror(s, 1);
    #elif defined(CAMERA_MODEL_ESP_EYE)
        s->set_vflip(s, 1);
        s->set_hmirror(s, 1);
        s->set_awb_gain(s, 1);
    #endif

    is_initialised = true;
    return true;
}

// -----------------------------------------------------------------------------------------
// CAMERA DE-INITIALIZATION.
// -----------------------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------------------
// CAMERA CAPTURE.
// -----------------------------------------------------------------------------------------

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
bool ei_camera_capture(uint32_t img_width, uint32_t img_height, uint8_t *out_buf) 
{
    bool do_resize = false;

    if (!is_initialised) {
        ei_printf("ERR: Camera is not initialized\r\n");
        return false;
    }

    camera_fb_t *fb = esp_camera_fb_get();

    if (!fb) 
    {
        ei_printf("Camera capture failed\n");
        return false;
    }

   bool converted = fmt2rgb888(fb->buf, fb->len, PIXFORMAT_JPEG, snapshot_buf);

   esp_camera_fb_return(fb);

   if(!converted){
       ei_printf("Conversion failed\n");
       return false;
   }

    if ((img_width != EI_CAMERA_RAW_FRAME_BUFFER_COLS)
        || (img_height != EI_CAMERA_RAW_FRAME_BUFFER_ROWS)) {
        do_resize = true;
    }

    if (do_resize) {
        ei::image::processing::crop_and_interpolate_rgb888(
        out_buf,
        EI_CAMERA_RAW_FRAME_BUFFER_COLS,
        EI_CAMERA_RAW_FRAME_BUFFER_ROWS,
        out_buf,
        img_width,
        img_height);
    }


    return true;
}

// -----------------------------------------------------------------------------------------
// CAMERA GET DATA.
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

#if !defined(EI_CLASSIFIER_SENSOR) || EI_CLASSIFIER_SENSOR != EI_CLASSIFIER_SENSOR_CAMERA
#error "Invalid model for current sensor"
#endif

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
    digitalWrite(RedLED_Pin, HIGH);

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
    digitalWrite(RedLED_Pin, LOW);

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

    Serial.begin(115200);  // Reduced Baud Rate for Better Stability.
    delay(100);  // Give Serial Time to Initialize.

    serialPrintWithDelay("\n--------------------------------");
    serialPrintWithDelay("Starting ESP32-CAM...");
    serialPrintWithDelay("--------------------------------");

    // Initialize camera.
    if (ei_camera_init() == false) 
    {
        cameraInitialized = false;
        ei_printf("Failed to initialize Camera!\r\n");
    }
    else 
    {
        cameraInitialized = true;
        ei_printf("Camera initialized\r\n");
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

// -----------------------------------------------------------------------------------------
// Process Image.
// -----------------------------------------------------------------------------------------

bool processImage() {
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
    ei_printf("Predictions (DSP: %d ms., Classification: %d ms., Anomaly: %d ms.): \n", result.timing.dsp, result.timing.classification, result.timing.anomaly);

    // Process the classifier results
    bool personDetected = false;

    #if EI_CLASSIFIER_OBJECT_DETECTION == 1
        ei_printf("Object detection bounding boxes:\r\n");
        for (uint32_t i = 0; i < result.bounding_boxes_count; i++) 
        {
            ei_impulse_result_bounding_box_t bb = result.bounding_boxes[i];
            if (bb.value == 0) 
            {
                continue;
            }
            ei_printf("  %s (%f) [ x: %u, y: %u, width: %u, height: %u ]\r\n",
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

    free(snapshot_buf);

    delay(100); // Small Delay.

    return personDetected;
}


// -----------------------------------------------------------------------------------------
// Check Motion Sensor.
// -----------------------------------------------------------------------------------------

void checkMotionSensor() {
    // Check motion sensor at regular intervals.

    if (millis() - lastMotionCheck >= MOTION_CHECK_INTERVAL) {
        lastMotionCheck = millis();
        /*
        // Read PIR sensor.
        int pirValue = digitalRead(PassiveIR_Pin);
        if (pirValue == HIGH) {
            Serial.println("\n[MOTION] PIR sensor detected motion");
            motionDetected = true;
            personDetected = false;
            
            if (processImage()) {
                notifyGadget();

                Serial.println("[INFO] Person detected in the image.");
                Serial.println("[INFO] Turning on lights...");

                digitalWrite(LEDStrip_Pin, HIGH);
                digitalWrite(Alarm_Pin, HIGH);

                Serial.println("[INFO] Triggering alarm...");
                Serial.println("[INFO] Sending notification to gadget...");

                delay(5000);

                digitalWrite(LEDStrip_Pin, LOW);
                digitalWrite(Alarm_Pin, LOW);

                Serial.println("[INFO] Alarm turned off.");
                Serial.println("[INFO] Lights turned off.");

                delay(2000);
            } else {
                Serial.println("[INFO] No person detected in the image.");
            }
        } else {
            motionDetected = false;
        }
        */

        // // Check If 'P' Key Was Pressed.
        if (Serial.available() > 0) {
            char input = Serial.read();
            
            // Check if 'P' was pressed.
            if (input == 'P') {
                Serial.println("\n[INPUT] 'P' key pressed - simulating motion detection.");
                
                // Capture Image.
                if (processImage()) {
                    notifyGadget();

                    Serial.println("[DETECTION] Person detected in the image.");
                    Serial.println("[INFO] Turning on lights...");

                    digitalWrite(LEDStrip_Pin, HIGH);
                    digitalWrite(Alarm_Pin, HIGH);

                    Serial.println("[INFO] Triggering alarm...");
                    Serial.println("[INFO] Sending notification to gadget...");

                    delay(5000);

                    digitalWrite(LEDStrip_Pin, LOW);
                    digitalWrite(Alarm_Pin, LOW);

                    Serial.println("[INFO] Alarm turned off.");
                    Serial.println("[INFO] Lights turned off.");

                delay(2000);
                } else {
                    Serial.println("[INFO] No person detected in image.");
                }
            }
        }

    }
}

// -----------------------------------------------------------------------------------------
// Initialize Hardware.
// -----------------------------------------------------------------------------------------

void initializeHardware() {
    serialPrintWithDelay("\n========== INITIALIZING HARDWARE ==========");

    // Initialize input pins.
    pinMode(PassiveIR_Pin, INPUT);
    pinMode(ActiveIR1_Pin, INPUT);
    pinMode(ChipEnable_Pin, INPUT_PULLUP);
    
    // Initialize output pins.
    pinMode(LEDStrip_Pin, OUTPUT);
    pinMode(Alarm_Pin, OUTPUT);
    pinMode(RedLED_Pin, OUTPUT);
    pinMode(WhiteLED_Pin, OUTPUT);
    
    // Set initial states.
    digitalWrite(LEDStrip_Pin, LOW);
    digitalWrite(Alarm_Pin, LOW);
    digitalWrite(RedLED_Pin, LOW);
    digitalWrite(WhiteLED_Pin, LOW);

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
    // -----

    // 1. Check Wi-Fi Connection & Reconnect If Disconnected.
    static unsigned long lastWiFiCheck = 0;
    const unsigned long WIFI_CHECK_INTERVAL = 10000; // Check every 10 seconds
    
    if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) {
        lastWiFiCheck = millis();
        checkWiFiConnection();
    }
    
    // -----

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
    
    // -----

    // 3. Check Motion Sensor at Regular Intervals.
    checkMotionSensor();
    
    // -----

    // 4. Check Heartbeat.
    if (millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) {
        lastHeartbeat = millis();
        missedHeartbeats++;
        
        if (missedHeartbeats >= MAX_MISSED_HEARTBEATS) {
            serialPrintWithDelay("[WARNING] Multiple heartbeats missed. Checking WiFi connection...");
            checkWiFiConnection();
        }
    }
    
    // -----

    // 5. Handle Alarm State.
    if (alarmActive) {
        // Toggle alarm for audible effect and LED for visual feedback.
        static unsigned long lastAlarmToggle = 0;
        if (millis() - lastAlarmToggle >= 500) {  // Toggle every 500ms
            lastAlarmToggle = millis();
            digitalWrite(Alarm_Pin, !digitalRead(Alarm_Pin));
            digitalWrite(RedLED_Pin, !digitalRead(RedLED_Pin));
            digitalWrite(WhiteLED_Pin, !digitalRead(WhiteLED_Pin));
        }
    }
    
    // Uncomment this section to test person detection notifications with the mobile app
    // 6. Test person detection simulation
    // simulatePersonDetection();
    
    
    // Small delay to prevent overwhelming the CPU
    delay(100);
}

// -----------------------------------------------------------------