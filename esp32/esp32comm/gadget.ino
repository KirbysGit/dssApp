#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <SPIFFS.h>

const char* WIFI_SSID = "RussellH203";
const char* WIFI_PASS = "Knights_H203!";
const int MAX_CONNECTION_ATTEMPTS = 20;
int connectionAttempts = 0;

// Add minimum RSSI threshold
const int MIN_RSSI = -85;  // Accept weaker signals
const int RETRY_DELAY = 2000;  // ms between connection attempts

AsyncWebServer server(80);

// Single buffer for the latest image
uint8_t* imageBuffer = nullptr;
size_t imageSize = 0;

void WiFiEventHandler(WiFiEvent_t event) {
    Serial.printf("[WiFi-event] event: %d\n", event);
    
    switch (event) {
        case SYSTEM_EVENT_STA_GOT_IP:
            Serial.print("Connected! IP address: ");
            Serial.println(WiFi.localIP());
            break;
        case SYSTEM_EVENT_STA_DISCONNECTED:
            Serial.println("Disconnected from WiFi access point");
            Serial.print("WiFi lost connection. Reason: ");
            Serial.println(WiFi.disconnect());
            break;
    }
}

void connectToWiFi() {
    if (WiFi.status() == WL_CONNECTED) {
        // Only stay connected if signal is above minimum threshold
        if (WiFi.RSSI() > MIN_RSSI) return;
        Serial.println("Signal too weak, attempting to reconnect...");
    }
    
    Serial.println("Attempting to connect to WiFi...");
    WiFi.disconnect(true, true);
    delay(RETRY_DELAY);  // Increased delay
    
    WiFi.mode(WIFI_STA);
    
    // Reduce TX power to prevent interference
    WiFi.setTxPower(WIFI_POWER_15dBm);  // Reduced from 19.5dBm
    
    // Set static IP configuration
    IPAddress staticIP(172, 20, 10, 8);
    IPAddress gateway(172, 20, 10, 1);
    IPAddress subnet(255, 255, 255, 0);
    IPAddress dns(8, 8, 8, 8);
    
    if (!WiFi.config(staticIP, gateway, subnet, dns)) {
        Serial.println("Static IP Configuration Failed");
    }
    
    // Optimize for weak signals
    WiFi.setAutoReconnect(true);
    WiFi.persistent(true);
    WiFi.setSleep(false);
    
    // Set lower data rate for better stability
    WiFi.setPhyMode(WIFI_PHY_MODE_11B);  // Use more stable 802.11b mode
    
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    
    unsigned long startAttemptTime = millis();
    int dots = 0;
    
    // Increased timeout for weak signals
    while (WiFi.status() != WL_CONNECTED && 
           millis() - startAttemptTime < 15000) {  // 15 second timeout
        delay(1000);  // Longer delay between checks
        Serial.print(".");
        if (++dots >= 15) {
            Serial.println();
            dots = 0;
        }
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        int rssi = WiFi.RSSI();
        Serial.println("\nConnected successfully!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        Serial.print("Signal Strength (RSSI): ");
        Serial.print(rssi);
        Serial.println(" dBm");
        Serial.print("Connection Quality: ");
        if (rssi >= -50) Serial.println("Excellent");
        else if (rssi >= -60) Serial.println("Good");
        else if (rssi >= -70) Serial.println("Fair");
        else Serial.println("Poor");
        
        Serial.print("MAC Address: ");
        Serial.println(WiFi.macAddress());
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
    
    // Register WiFi event handler
    WiFi.onEvent(WiFiEventHandler);
    
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
    static unsigned long lastCheck = 0;
    
    // Regular connection check
    unsigned long currentMillis = millis();
    if (currentMillis - lastCheck >= 1000) {  // Check every second
        lastCheck = currentMillis;
        
        if (WiFi.status() == WL_CONNECTED) {
            // Print connection stats every 30 seconds
            static unsigned long lastStats = 0;
            if (currentMillis - lastStats >= 30000) {
                lastStats = currentMillis;
                Serial.printf("Connection stable - RSSI: %d dBm\n", WiFi.RSSI());
            }
        } else if (currentMillis - lastReconnectAttempt >= reconnectInterval) {
            Serial.println("WiFi disconnected. Attempting to reconnect...");
            connectToWiFi();
            lastReconnectAttempt = currentMillis;
        }
    }
    
    delay(100);  // Reduced delay for more responsive handling
}