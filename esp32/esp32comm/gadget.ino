// Imports.
#include <WebServer.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Microrouter Network.
const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";

// Server on port 80.
WebServer server(80);

// ---------
// CONSTANTS
// ---------

// Trigger Alarm.
const int TRIGGER_ALARM_PIN = 4;

// Turn On Lights.
const int TURN_ON_LIGHTS_PIN = 5;

// Turn Off Alarm.
const int TURN_OFF_ALARM_PIN = 6;

// Extra LED Pins.
const int LED1 = 16;
const int LED2 = 17;
const int LED3 = 18;

// Switch Debounce Variables.
unsigned long lastSwitchPressTime = 0;
const unsigned long DEBOUNCE_DELAY = 200; // 200ms debounce time

// -----------------------------------------------------------------------------------------
// Camera Node Struct.
// -----------------------------------------------------------------------------------------

struct CameraNode {
  String url;
  String name;
  unsigned long lastSeen;
};

// Max number of cameras.
#define MAX_CAMERAS 5

// Camera Node Array.
CameraNode cameras[MAX_CAMERAS];

// # of Cameras.
int numCameras = 0;

// Person Detection Flag.
bool personDetected = false;

// -----------------------------------------------------------------------------------------
// Person Detection Handler.
// -----------------------------------------------------------------------------------------

void handlePersonDetected() {
  Serial.println("\n========== PERSON DETECTION NOTIFICATION ==========");
  Serial.println("Time: " + String(millis()));
  Serial.println("Sender IP: " + server.client().remoteIP().toString());
  String postBody = server.arg("plain");
  Serial.println("\nReceived POST data: [" + postBody + "]");
  Serial.println("POST data length: " + String(postBody.length()));

  // Create a JSON document.
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, postBody);

  // Check for JSON parsing errors.
  if (error) {
      Serial.print("[ERROR] JSON parsing failed! Error: ");
      Serial.println(error.c_str());
      Serial.println("==============================================\n");
      server.send(400, "text/plain", "Invalid JSON format");
      return;
  }

  // Extract values from JSON.
  const char* cameraUrl = doc["camera_url"];
  const char* nodeName = doc["node"];
  const char* timestamp = doc["timestamp"];

  // Print parsed JSON values.
  Serial.println("\nParsed JSON values:");
  Serial.println("Camera URL: [" + String(cameraUrl ? cameraUrl : "null") + "]");
  Serial.println("Node Name: [" + String(nodeName ? nodeName : "null") + "]");
  Serial.println("Timestamp: [" + String(timestamp ? timestamp : "null") + "]");

  // Check for missing or empty camera URL or node name.
  if (!cameraUrl || strlen(cameraUrl) == 0 || !nodeName || strlen(nodeName) == 0) {
      Serial.println("[ERROR] Missing or empty camera URL or node name");
      server.send(400, "text/plain", "Missing or empty camera URL or node name");
      return;
  }

  // Update or Add Camera to our List.
  bool found = false;
  for (int i = 0; i < numCameras; i++) {
      if (cameras[i].name == nodeName) {
          cameras[i].url = cameraUrl;
          cameras[i].lastSeen = millis();
          found = true;
          Serial.printf("Updated existing camera %s with URL %s\n", nodeName, cameraUrl);
          break;
      }
  }

  // Add New Camera to our List.
  if (!found && numCameras < MAX_CAMERAS) {
      cameras[numCameras].url = cameraUrl;
      cameras[numCameras].name = nodeName;
      cameras[numCameras].lastSeen = millis();
      numCameras++;
      Serial.printf("Added new camera %s with URL %s, total cameras: %d\n", 
                  nodeName, cameraUrl, numCameras);
  }

  // Set Person Detected Flag.
  personDetected = true;

  // Create Response JSON with Camera Information.
  String response = "{";
  response += "\"status\":\"success\",";
  response += "\"message\":\"Detection recorded\",";
  response += "\"camera_url\":\"" + String(cameraUrl) + "\",";
  response += "\"node\":\"" + String(nodeName) + "\",";
  response += "\"timestamp\":\"" + String(timestamp ? timestamp : "") + "\"";
  response += "}";
  
  // Send Response.
  server.send(200, "application/json", response);
    
  Serial.println("==============================================\n");
}

// -----------------------------------------------------------------------------------------
// Person Status Endpoint.
// -----------------------------------------------------------------------------------------

void handlePersonStatus() {

  // Create response JSON.
  String response = "{";
  response += "\"personDetected\":" + String(personDetected ? "true" : "false") + ",";
  response += "\"cameras\":[";
    
  // Iterate through Cameras and Add to Response.
  for (int i = 0; i < numCameras; i++) {
      if (i > 0) response += ",";
      response += "{";
      response += "\"name\":\"" + cameras[i].name + "\",";
      response += "\"url\":\"" + cameras[i].url + "\",";
      response += "\"lastSeen\":" + String(cameras[i].lastSeen);
      response += "}";
  }
  
  // Close response.
  response += "]}";
    
  // Send response.
  server.send(200, "application/json", response);
    
  // Reset person detected flag after sending status.
  personDetected = false;
}

// -----------------------------------------------------------------------------------------
// Ping Handler.
// -----------------------------------------------------------------------------------------

void handlePing() {
    Serial.println("\n========== PING REQUEST ==========");
    Serial.println("Time: " + String(millis()));
    Serial.println("Client IP: " + server.client().remoteIP().toString());
    Serial.println("Connection Status: " + String(WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected"));
    Serial.println("Signal Strength (RSSI): " + String(WiFi.RSSI()) + " dBm");
    Serial.println("=================================\n");
      
    server.send(200, "application/json", "{\"status\":\"connected\"}");
}

// -----------------------------------------------------------------------------------------
// Notify Node.
// -----------------------------------------------------------------------------------------

// Controller Function for Endpoints.
void notifyNode(String endpoint) {
    // Check if WiFi is connected.
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[ERROR] Cannot notify nodes: WiFi not connected");
        return;
    }

    // Iterate through All Connected Cameras.
    for (int i = 0; i < numCameras; i++) {
        // Create HTTP client.
        HTTPClient http;
        
        // Extract Base URL from Camera URL and Append the Endpoint.
        String nodeUrl = cameras[i].url;

        // Remove "/capture" from the end if it exists.
        nodeUrl = nodeUrl.substring(0, nodeUrl.lastIndexOf('/'));
        String url = nodeUrl + endpoint;

        // Print notification.
        Serial.println("Sending request to node " + cameras[i].name + ": " + url);
        
        // Check if HTTP Connection is Successful.
        if (!http.begin(url)) {
            Serial.println("[ERROR] Failed to begin HTTP connection to " + cameras[i].name);
            continue;
        }
        
        // Set Timeout.
        http.setTimeout(5000);

        // Send GET Request.
        int httpCode = http.GET();
        
        // Check if Request was Successful.
        if (httpCode == HTTP_CODE_OK) {
            String response = http.getString();
            Serial.println("Node " + cameras[i].name + " response: " + response);
            Serial.println("Command acknowledged successfully");
        } else {
            Serial.printf("[ERROR] Node %s did not acknowledge command. Error code: %d\n", 
                        cameras[i].name.c_str(), httpCode);
        }

        http.end();
    }
}

//// -----------------------------------------------------------------------------------------
// Test Gadget Switches.
// -----------------------------------------------------------------------------------------

// Test Trigger Alarm from Gadget from Mobile App.
void handleTestTriggerAlarm() {
    Serial.println("[TEST] Trigger Alarm Command Received");
    notifyNode("/trigger_alarm");
    server.send(200, "text/plain", "Test trigger alarm command executed");
}

// Test Turn Off Alarm from Gadget from Mobile App.
void handleTestTurnOffAlarm() {
    Serial.println("[TEST] Turn Off Alarm Command Received");
    notifyNode("/turn_off_alarm");
    server.send(200, "text/plain", "Test turn off alarm command executed");
}

// Test Turn On Lights from Gadget from Mobile App.
void handleTestTurnOnLights() {
    Serial.println("[TEST] Turn On Lights Command Received");
    notifyNode("/turn_on_lights");
    server.send(200, "text/plain", "Test turn on lights command executed");
}

// Test Turn Off Lights from Gadget from Mobile App.
void handleTestTurnOffLights() {
    Serial.println("[TEST] Turn Off Lights Command Received");
    notifyNode("/turn_off_lights");
    server.send(200, "text/plain", "Test turn off lights command executed");
}

// Test Restart Gadget from Gadget from Mobile App.
void handleTestRestartGadget() {
    Serial.println("[TEST] Restart Gadget Command Received");
    server.send(200, "text/plain", "Restarting gadget...");
    delay(1000);
    ESP.restart();
}

// -----------------------------------------------------------------------------------------
// Switch Monitoring
// -----------------------------------------------------------------------------------------

void checkSwitches() {
    // Get Current Time.
    unsigned long currentMillis = millis();
    
    // Debounce switch presses.
    if (currentMillis - lastSwitchPressTime > DEBOUNCE_DELAY) {

        // Check trigger alarm switch.
        if (digitalRead(TRIGGER_ALARM_PIN) == LOW) {

            // Print notification.
            Serial.println("[INPUT] Trigger Alarm Switch Activated");
            
            // Notify node.
            notifyNode("/trigger_alarm");

            // Update last switch press time.
            lastSwitchPressTime = currentMillis;
        }

        // Check turn on lights switch.
        if (digitalRead(TURN_ON_LIGHTS_PIN) == LOW) {

            // Print notification.
            Serial.println("[INPUT] Turn On Lights Switch Activated");

            // Notify node.
            notifyNode("/turn_on_lights");

            // Update last switch press time.
            lastSwitchPressTime = currentMillis;
        }

        // Check turn off alarm switch.
        if (digitalRead(TURN_OFF_ALARM_PIN) == LOW) {

            // Print notification.
            Serial.println("[INPUT] Turn Off Alarm Switch Activated");

            // Notify node.
            notifyNode("/turn_off_alarm");

            // Update last switch press time.
            lastSwitchPressTime = currentMillis;
          }
    }
}

// -----------------------------------------------------------------------------------------
// Setup Function.
// -----------------------------------------------------------------------------------------

void setup()
{
    // Initialize pins.
    pinMode(TRIGGER_ALARM_PIN, INPUT_PULLUP);
    pinMode(TURN_ON_LIGHTS_PIN, INPUT_PULLUP);
    pinMode(TURN_OFF_ALARM_PIN, INPUT_PULLUP);

    // Start Serial Communication.
    Serial.begin(115200);
    Serial.println("--------------------------------");
    Serial.println("Starting ESP32-S3 Gadget...");
    Serial.println("--------------------------------");

    // Configure Wifi Connection.
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    // Wait For Wifi To Connect.
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 30) {
        delay(1000);
        Serial.print(".");
        attempts++;
    }

    // Wifi Connection Result.
    if (WiFi.status() == WL_CONNECTED) {
        // Print Connection Success.
        Serial.println("\n----------------------------");
        Serial.println("WiFi Connected Successfully!");
        Serial.print("ESP32-S3 IP Address: ");
        Serial.println(WiFi.localIP());
        Serial.print("Signal Strength (RSSI): ");
        Serial.print(WiFi.RSSI());
        Serial.println(" dBm");
        Serial.println("----------------------------\n");

        // Setup Server Endpoints.  
        server.on("/person_status", HTTP_GET, handlePersonStatus);
        server.on("/person_detected", HTTP_POST, handlePersonDetected);
        server.on("/ping", HTTP_GET, handlePing);

        // Test Endpoints.
        server.on("/test_trigger_alarm", HTTP_GET, handleTestTriggerAlarm);
        server.on("/test_turn_off_alarm", HTTP_GET, handleTestTurnOffAlarm);
        server.on("/test_turn_on_lights", HTTP_GET, handleTestTurnOnLights);
        server.on("/test_turn_off_lights", HTTP_GET, handleTestTurnOffLights);
        server.on("/test_restart_gadget", HTTP_GET, handleTestRestartGadget);
            
        // Start The Web Server.
        server.begin(); 
        Serial.println("HTTP server started successfully");
        Serial.println("Available endpoints:");
        Serial.println("GET  /person_status - Check person detection status");
        Serial.println("POST /person_detected - Receive person detection notifications");
        Serial.println("GET  /ping - Check connection status");

        // Test Endpoints.
        Serial.println("GET  /test_trigger_alarm - Test trigger alarm command");
        Serial.println("GET  /test_turn_off_alarm - Test turn off alarm command");
        Serial.println("GET  /test_turn_on_lights - Test turn on lights command");
        Serial.println("GET  /test_turn_off_lights - Test turn off lights command");
        Serial.println("GET  /test_restart_gadget - Restart gadget");
        Serial.println("--------------------------------");
    } else {
        // Print Error.
        Serial.println("\n[ERROR] Failed to connect to WiFi after 30 attempts.");
        Serial.println("Please check your WiFi credentials and router settings.");
        Serial.println("Restarting in 5 seconds...");
        delay(5000);
        ESP.restart();
    }
}


void checkWifiConnection() {
    // Check Wi-Fi Connection Every 10 Seconds.
    if (millis() - lastWiFiCheck > 10000) {
        lastWiFiCheck = millis();
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("[WARNING] Wi-Fi Lost! Attempting To Reconnect...");
        }

        // Disconnect and reconnect.
        WiFi.disconnect();
        WiFi.reconnect();

        // Attempts to reconnect.
        int attempts = 0;

        // Blink LED to show we're trying to reconnect.
        while (WiFi.status() != WL_CONNECTED && attempts < 20) {
            delay(1000);
            Serial.print(".");
            attempts++;
        }

        // Reconnect success.
        if (WiFi.status() == WL_CONNECTED) {
            Serial.println("\nWi-Fi Reconnected Successfully!");
        } else {
            // Print error and restart.
            Serial.println("\n[ERROR] Failed To Reconnect. Restarting...");
            delay(5000);
            ESP.restart();
        }
    }
}
// -----------------------------------------------------------------------------------------
// Main Loop.
// -----------------------------------------------------------------------------------------

void loop()
{
    // Check Wi-Fi Connection and Reconnect if Disconnected
    static unsigned long lastWiFiCheck = 0;

    // Check Wi-Fi Connection and Reconnect if Disconnected.
    checkWifiConnection();

    // Handle Incoming HTTP Requests.
    server.handleClient();
        
    // Check Hardware Switches.
    checkSwitches();
        
    // Blink LED Occasionally To Show The Device Is Running.
    static unsigned long lastBlink = 0;
    if (millis() - lastBlink > 2000 && WiFi.status() == WL_CONNECTED) {
        //digitalWrite(LED, !digitalRead(LED));
        lastBlink = millis();
    }
}

// -----------------------------------------------------------------
//                      main.ino(Gadget)
// -----------------------------------------------------------------