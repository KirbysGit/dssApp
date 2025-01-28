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
const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";
 
// Server on port 80.
// WebServer server(80);

// ----------
// RESOLUTION
// ----------
 
// Low Resolution.
static auto modelRes = esp32cam::Resolution::find(96, 96); 

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
  
  // // Create HTTP client.
  HTTPClient http;
  http.begin("http://192.168.1.120/image_upload");

  // Set headers to indicate raw image data.
  http.addHeader("Content-Type", "text/plain"); // Assuming JPEG format

  // Send image data in the request body
  int httpResponseCode = http.POST(imageData, imageSize);

  if (httpResponseCode > 0)
  {
    String response = http.getString();
    Serial.println("HTTP Response Code: " + String(httpResponseCode));
    Serial.println("Captured and sent image!!! Your an absolute beast Jaxon.");
  } 
  else 
  {
    Serial.println("Failed to send image!");
  }

  // Free camera frame buffer memory
  esp_camera_fb_return(fb);
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

// Setup function that initializes esp32-cam.
void  setup()
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
    
    // Log if camera was succesful.
    bool ok = Camera.begin(cfg);
    // Serial.println(ok ? "CAMERA OK" : "CAMERA FAIL");
  }  

  // Configure wifi connection.
  // Disable wifi persistence.
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);  // Wifi to station mode.
  WiFi.begin(WIFI_SSID, WIFI_PASS); // Connect to the wifi network.

  // pinMode(PassiveIR_Pin, INPUT); // Setup PIR sensor
  // pinMode(Tamper_Pin, INPUT_PULLUP); // Setup Tampering pin.

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