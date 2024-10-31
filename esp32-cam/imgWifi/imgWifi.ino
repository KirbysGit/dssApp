#include <TensorFlowLite_ESP32.h>

#include <WebServer.h>
#include <esp32cam.h>
#include <WiFi.h>
#include <HTTPClient.h>

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz Wi-Fi band.
const char* WIFI_SSID = "mi telefono";
const char* WIFI_PASS = "password";

// Server on port 80.
WebServer server(80);

// ----------
// RESOLUTION
// ----------

// Low Resolution.
static auto loRes = esp32cam::Resolution::find(320, 240); 

// Mid Resolution.
static auto midRes = esp32cam::Resolution::find(640, 480);

// High Resolution
static auto hiRes = esp32cam::Resolution::find(800, 600);

// ---------
// CONSTANTS
// ---------

// PIR sensor pin.
const byte pirPin = GPIO_NUM_13;

// ----
// CODE
// ----

// Function to serve the captured image
void serveJpg() {
  auto frame = esp32cam::capture();
  if (frame == nullptr) {
    Serial.println("Camera capture failed");
    server.send(503, "text/plain", "Camera capture failed");
    return;
  }

  // Set the content length
  server.setContentLength(frame->size());

  // Send the response headers
  server.send(200, "image/jpeg", "");

  // Send the image data
  server.client().write(frame->data(), frame->size());
}

// Handle High Res request
void handleJpgHi() {
  if (!esp32cam::Camera.changeResolution(hiRes)) {
    Serial.println("SET-HI-RES FAIL");
  }
  serveJpg();
}

// Setup function that initializes ESP32-CAM.
void setup() {
  Serial.begin(115200);
  Serial.println("--------------------------------");
  Serial.println("Serial communication starting...");
  Serial.println("--------------------------------");

  // Configure ESP32-CAM.
  {
    using namespace esp32cam;
    Config cfg;

    // Set pin configuration for AiThinker model.
    cfg.setPins(pins::AiThinker);

    // Set resolution to high by default.
    cfg.setResolution(hiRes);
    
    // Buffer count for image processing.
    cfg.setBufferCount(1);  // Reduce buffer count to save memory

    // Set image quality (10 is highest quality, 63 is lowest)
    cfg.setJpeg(30);  // Adjust quality to reduce memory usage
    
    // Initialize the camera
    bool ok = Camera.begin(cfg);
    Serial.println(ok ? "CAMERA OK" : "CAMERA FAIL");
    if (!ok) {
      // If camera initialization fails, restart the ESP32-CAM
      Serial.println("Camera initialization failed. Restarting...");
      ESP.restart();
    }
  }

  // Configure Wi-Fi connection.
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  // Start the web server before connecting to Wi-Fi
  server.on("/cam-hi.jpg", handleJpgHi);
  server.begin();

  // Wait for Wi-Fi to connect.
  Serial.println("Connecting to Wi-Fi...");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    Serial.print("WiFi Status: ");
    Serial.println(WiFi.status());
    Serial.println("Connecting ESP32-CAM to Wi-Fi...");
    delay(2000);
    attempts++;
  }

  // Check if Wi-Fi is connected
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected to Wi-Fi!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nFailed to connect to Wi-Fi. Restarting...");
    ESP.restart();
  }

  // Print the available URL
  Serial.println("Use the following URL to view the image:");
  Serial.print("http://");
  Serial.print(WiFi.localIP());
  Serial.println("/cam-hi.jpg");
}

// Main loop that continuously listens for client requests.
void loop() {
  // Handle incoming HTTP requests.
  server.handleClient();
}
