#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <SPIFFS.h>

const char* WIFI_SSID = "RussellH203";
const char* WIFI_PASS = "Knights_H203!";

AsyncWebServer server(80);

// Buffer for latest image from each camera
struct CameraBuffer {
  uint8_t* data;
  size_t size;
  unsigned long timestamp;
};

std::map<String, CameraBuffer> cameraBuffers;

void handleImageUpload(AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
  String cameraId = request->header("Camera-ID");
  
  Serial.printf("Receiving image: %d bytes (index: %d, total: %d)\n", len, index, total);
  Serial.printf("Free PSRAM: %d bytes\n", ESP.getFreePsram());
  
  if (cameraBuffers.find(cameraId) != cameraBuffers.end()) {
    Serial.println("Freeing old buffer");
    free(cameraBuffers[cameraId].data);
    cameraBuffers.erase(cameraId);
  }

  if (index == 0) { // First chunk
    uint8_t* newBuffer = (uint8_t*)ps_malloc(total);
    if (newBuffer) {
      Serial.println("Buffer allocated successfully");
      memcpy(newBuffer, data, len);
      cameraBuffers[cameraId] = {
        .data = newBuffer,
        .size = total,
        .timestamp = millis()
      };
    } else {
      Serial.println("Failed to allocate buffer!");
      request->send(507, "text/plain", "Insufficient storage");
      return;
    }
  } else if (cameraBuffers.find(cameraId) != cameraBuffers.end()) {
    memcpy(cameraBuffers[cameraId].data + index, data, len);
  }
  
  if (index + len == total) {
    Serial.println("Image received completely");
    request->send(200, "text/plain", "Image stored");
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("Starting...");
  
  if (!psramFound()) {
    Serial.println("PSRAM not found - this won't work without PSRAM!");
    while(1) delay(1000);
  }
  
  Serial.printf("Total PSRAM: %d bytes\n", ESP.getPsramSize());
  Serial.printf("Free PSRAM: %d bytes\n", ESP.getFreePsram());
  
  if (!SPIFFS.begin(true)) {
    Serial.println("SPIFFS Mount Failed");
    return;
  }

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");

  server.on(
    "/image_upload",
    HTTP_POST,
    [](AsyncWebServerRequest *request) {},
    NULL,
    handleImageUpload
  );

  server.on("/latest-image", HTTP_GET, [](AsyncWebServerRequest *request) {
    String cameraId = request->arg("camera_id");
    if (cameraBuffers.find(cameraId) != cameraBuffers.end()) {
      AsyncWebServerResponse *response = request->beginResponse_P(
        200,
        "image/jpeg",
        cameraBuffers[cameraId].data,
        cameraBuffers[cameraId].size
      );
      request->send(response);
    } else {
      request->send(404);
    }
  });

  server.begin();
}

void loop() {
  // Clean up old images if needed
  for (auto it = cameraBuffers.begin(); it != cameraBuffers.end(); ) {
    if (millis() - it->second.timestamp > 60000) {  // Remove images older than 1 minute
      free(it->second.data);
      it = cameraBuffers.erase(it);
    } else {
      ++it;
    }
  }
  delay(1000);
}