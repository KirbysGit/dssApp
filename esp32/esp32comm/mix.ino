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
// Jaxon Topel   1/20/2025       Transition to new IP algorithm
// Jaxon Topel   2/26/2025       IP Algorithm Updates
//
// Note(1): ChatGPT aided in the development of this code.
// Note(2): To run this code in arduino ide, please use ai
// thinker cam, 115200 baud rate to analyze serial communication,
// and enter both the password and wifi to work within the network.
//
// -----------------------------------------------------------------

// --------
// INCLUDES
// --------

#include <Person_detector_x2_inferencing.h>     // Header for Edge impulse project.
#include "edge-impulse-sdk/dsp/image/image.hpp" // Provides Image processing functions.
#include "esp_camera.h"                         // Manages Camera Initialization.
#include <WiFi.h>                               // Manages WiFi connectivity.
#include <HTTPClient.h>                         // Enables HTTP Communication.
#include <WebServer.h>

WebServer server(80);

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz wifi band.
const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";

// Global variable for Gadget & mobile app.
const char* GADGET_IP = "http://192.168.8.206";
const char* APP_IP = "x";

// ---------
// CONSTANTS
// ---------

// Passive IR sensor pin.
const int PassiveIR_Pin         = 12;
const int Clock_Pin             = 14;
const int LEDStrip_Pin          = 15;
// const int LED2               = 2;
const int Alarm_Pin             = 13;
const int whitePin              = 3;
// const int Tamper_Pin            = 1;

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
#define EI_CAMERA_RAW_FRAME_BUFFER_COLS           320
#define EI_CAMERA_RAW_FRAME_BUFFER_ROWS           240
#define EI_CAMERA_FRAME_BYTE_SIZE                 3

// Private variables
static bool debug_nn = false; // Set this to true to see e.g. features generated from the raw signal
static bool is_initialised = false;
uint8_t *snapshot_buf; // points to the output of the capture

// Configure camera.
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

// Main Setup Function.
void setup()
{
    Serial.begin(115200);
    Serial.println("--------------------------------");
    Serial.println("Serial communication starting...");
    Serial.println("--------------------------------");

    // Initialize Passive IR sensor pin
    pinMode(PassiveIR_Pin, INPUT); // Set PassiveIR_Pin as input

    // pinMode(Tamper_Pin, INPUT_PULLUP); // Setup Tampering pin.

    Serial.println("New test v3");

    // digitalWrite(33, LOW);
    // digitalWrite(33, HIGH);
    
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
    WiFi.persistent(false);
    WiFi.mode(WIFI_STA);  // Wifi to station mode.
    WiFi.begin(WIFI_SSID, WIFI_PASS); // Connect to the wifi network.

    // Start the server and define the endpoint for sounding alarm.
    server.on("/sound_alarm", HTTP_GET, soundAlarm);
    server.on("/capture", HTTP_GET, handleCapture);
    server.on("/disable_alarm", HTTP_GET, disableAlarm);
    server.on("/enable_lights", HTTP_GET, enableLights);
    server.begin();
    Serial.println("HTTP server started");

    // Wifi attempt tracker, ensure fast connection.
    int attempts = 0;

    // Wait for wifi to connect.
    while (WiFi.status() != WL_CONNECTED && attempts < 30) 
    {
        Serial.print("WiFi Status: ");
        Serial.println(WiFi.status());
        Serial.println("Connecting ESP32-CAM to wifi...");
        delay(2000);
        attempts++;
    }

    // Wifi connection success.
    if (WiFi.status() == WL_CONNECTED) 
    {
        Serial.print("Connected! IP Address: ");
        Serial.println(WiFi.localIP());
    } 
    
    // Wifi connection fail.
    else 
    {
        Serial.println("Failed to connect to WiFi. Restarting...");
        ESP.restart();  // Restart ESP32 if connection fails
    }

    Serial.print("http://");
    Serial.println(WiFi.localIP());

    ei_printf("\nWaiting for Passive IR trigger to start image processing...\n");
}

void handleCapture()
{
    camera_fb_t *fb = esp_camera_fb_get();
    if(!fb)
    {
        server.send(500, "text/plain", "Camera capture failed");
        return;
    }

    // Clear existing headers.
    server.client().flush();

    // Set headers properly.
    server.sendHeader("Content-Type", "image/jpeg");
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Connection", "close");

    // send response with content length.
    server.setContentLength(fb->len);
    server.send(200);

    // Send the image data.
    WiFiClient client = server.client();
    client.write(fb->buf, fb->len);

    // Clean up.
    esp_camera_fb_return(fb);
    Serial.printf("Sent image: %d bytes\n", fb->len);
}

void enableLights()
{
    // Turn on LED's.
    digitalWrite(LEDStrip_Pin, HIGH); // turn on
}

void disableAlarm()
{
    // digitally write to disable alarm.
    digitalWrite(Alarm_Pin, LOW); // turn off

    // Turn off LED's.
    digitalWrite(LEDStrip_Pin, LOW); // turn off
}

void soundAlarm()
{
    // Digitally write to alarm to sound it high.
    digitalWrite(Alarm_Pin, HIGH); // turn on

    // Turn on LED's.
    digitalWrite(LEDStrip_Pin, HIGH); // turn on
}

// Function to send an HTTP POST request to the gadget
void sendAlertToGadget()
{
    if (WiFi.status() == WL_CONNECTED) 
    {
        HTTPClient http;
        http.begin(String("http://") + GADGET_IP + "/person_detected");

        // Prepare JSON payload
        String payload = "{";
        payload += "\"event\": \"person_detected\", ";
        payload += "}";

        http.addHeader("Content-Type", "application/json");

        // Send the POST request
        int httpResponseCode = http.POST(payload);

        // Handle the response
        if (httpResponseCode > 0) 
        {
            Serial.printf("Alert sent to gadget. HTTP Response: %d\n", httpResponseCode);
        } 
        else 
        {
            Serial.printf("Failed to send alert. Error: %s\n", http.errorToString(httpResponseCode).c_str());
        }

        http.end(); // Close the connection
    } 
    else 
    {
        Serial.println("WiFi disconnected. Cannot send alert.");
    }
}

// Main Loop Function
void loop()
{
  // (1) If passive IR sensor detects motion.
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

    if (personDetected) 
    {
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
    } 
    else 
    {
        Serial.println("[INFO] No person detected in the image.");
    }

    free(snapshot_buf);
  }

  delay(100); // Small delay to avoid rapid polling
}

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

    //initialize the camera
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