#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <SPIFFS.h>

const char* WIFI_SSID = "RussellH203";
const char* WIFI_PASS = "Knights_H203!";
const int MAX_CONNECTION_ATTEMPTS = 10;
int connectionAttempts = 0;

AsyncWebServer server(80);

// Single buffer for the latest image
uint8_t* imageBuffer = nullptr;
size_t imageSize = 0;

void connectToWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  
  Serial.println("Attempting to connect to WiFi...");
  WiFi.disconnect(true);  // Disconnect from any previous connections
  delay(1000);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  
  unsigned long startAttemptTime = millis();
  
  while (WiFi.status() != WL_CONNECTED && 
         millis() - startAttemptTime < 10000) {  // 10 second timeout
    delay(500);
    Serial.print(".");
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected successfully!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength (RSSI): ");
    Serial.println(WiFi.RSSI());
    connectionAttempts = 0;
  } else {
    Serial.println("\nConnection failed!");
    Serial.print("WiFi Status: ");
    Serial.println(WiFi.status());
    connectionAttempts++;
    
    if (connectionAttempts >= MAX_CONNECTION_ATTEMPTS) {
      Serial.println("Max connection attempts reached. Restarting ESP32...");
      ESP.restart();
    }
  }
}

void handleImageUpload(AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
  Serial.printf("Receiving image: %d bytes (index: %d, total: %d)\n", len, index, total);

  if (index == 0) {
    if (imageBuffer != nullptr) {
      free(imageBuffer);
    }
    imageBuffer = (uint8_t*)ps_malloc(total);
    imageSize = total;
    
    if (!imageBuffer) {
      Serial.println("Failed to allocate buffer!");
      request->send(507, "text/plain", "Insufficient storage");
      return;
    }
    memcpy(imageBuffer, data, len);
  } else if (imageBuffer != nullptr) {
    memcpy(imageBuffer + index, data, len);
  }
  
  if (index + len == total) {
    Serial.println("Image received completely");
    request->send(200, "text/plain", "Image stored");
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("Starting...");
  
  // Set WiFi power
  WiFi.setTxPower(WIFI_POWER_19_5dBm);  // Maximum power
  
  connectToWiFi();
  
  if (WiFi.status() == WL_CONNECTED) {
    server.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
      request->send(200, "text/plain", "ESP32-S3 Server Running");
    });

    server.on(
      "/image_upload",
      HTTP_POST,
      [](AsyncWebServerRequest *request) {},
      NULL,
      handleImageUpload
    );

    server.on("/latest-image", HTTP_GET, [](AsyncWebServerRequest *request) {
      if (imageBuffer != nullptr && imageSize > 0) {
        AsyncWebServerResponse *response = request->beginResponse_P(
          200,
          "image/jpeg",
          imageBuffer,
          imageSize
        );
        response->addHeader("Access-Control-Allow-Origin", "*");
        request->send(response);
      } else {
        request->send(404, "text/plain", "No image available");
      }
    });

    server.begin();
    Serial.println("HTTP server started");
  }
}

void loop() {
  static unsigned long lastReconnectAttempt = 0;
  const unsigned long reconnectInterval = 5000; // 5 seconds between attempts
  
  if (WiFi.status() != WL_CONNECTED) {
    unsigned long currentMillis = millis();
    if (currentMillis - lastReconnectAttempt >= reconnectInterval) {
      Serial.println("WiFi disconnected. Attempting to reconnect...");
      connectToWiFi();
      lastReconnectAttempt = currentMillis;
    }
  }
  
  delay(1000);
}