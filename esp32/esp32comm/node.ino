#include <WebServer.h>
#include <esp32cam.h>
#include <WiFi.h>
#include <HTTPClient.h>

const char* WIFI_SSID = "mi telefono";
const char* WIFI_PASS = "password";
const char* GADGET_URL = "http://172.20.10.8/image_upload";

WebServer server(80);
static auto hiRes = esp32cam::Resolution::find(800, 600);

void handleCapture() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    server.send(500, "text/plain", "Camera capture failed");
    return;
  }

  server.send_P(200, "image/jpeg", (const char *)fb->buf, fb->len);
  esp_camera_fb_return(fb);
}

void setup() {
  Serial.begin(115200);
  
  // Camera config
  {
    using namespace esp32cam;
    Config cfg;
    cfg.setPins(pins::AiThinker);
    cfg.setResolution(hiRes);
    cfg.setBufferCount(2);
    cfg.setJpeg(80);
    
    bool ok = Camera.begin(cfg);
    if (!ok) {
      Serial.println("Camera init failed");
      ESP.restart();
    }
  }

  // WiFi config
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
  Serial.print("Camera Ready! Use 'http://");
  Serial.print(WiFi.localIP());
  Serial.println("/capture' to take a photo");

  server.on("/capture", handleCapture);
  server.begin();
}

void loop() {
  server.handleClient();
}