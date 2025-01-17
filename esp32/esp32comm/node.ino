#include <WebServer.h>
#include <esp32cam.h>
#include <WiFi.h>
#include <HTTPClient.h>

const char* WIFI_SSID = "RussellH203";
const char* WIFI_PASS = "Knights_H203!";
const char* GADGET_URL = "http://192.168.1.120/image_upload";

static auto hiRes = esp32cam::Resolution::find(800, 600);

void captureAndSendImage() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    return;
  }

  HTTPClient http;
  http.begin(GADGET_URL);
  http.addHeader("Content-Type", "image/jpeg");
  http.addHeader("Camera-ID", "CAM1");  // Unique ID for each camera

  int httpCode = http.POST(fb->buf, fb->len);
  
  if (httpCode == 200) {
    Serial.println("Image sent successfully");
  } else {
    Serial.printf("Image send failed, code: %d\n", httpCode);
  }

  esp_camera_fb_return(fb);
  http.end();
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
}

void loop() {
  captureAndSendImage();
  delay(5000);  // Adjust timing as needed
}