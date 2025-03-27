// -----------------------------------------------------------------
//                      main.ino(Gadget)
//
//
// Description: Central point where the code runs on our 
//              esp gadget.
//
// Name:         Date:           Description:
// -----------   ---------       ----------------
// Jaxon Topel   9/24/2024       Initial Creation
// Jaxon Topel   10/12/2024      Initial Object Detection work
// Jaxon Topel   12/20/2024      Gadget GPIO pin integration
// Jaxon Topel   12/20/2024      Loop functionality architecture development
// Jaxon Topel   1/13/2025       Architect Communication Network for Node/Gadget
// Jaxon Topel   1/17/2025       Communication Network debugging, data integrity checks, IP alg debugging
// Jaxon Topel   1/20/2025       Sending image from Node to Gadget
// Jaxon Topel   3/1/2025        Testing and Revision phase 1 integration
//
// Note(1): ChatGPT aided in the development of this code.
// Note(2): To run this code in arduino ide, please use , set baud
// rate to 115200 to analyze serial communication, and enter both
// the password and wifi to work within the network.
// -----------------------------------------------------------------

// Imports.
#include <WebServer.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Kirby's Hotspot.
/*
 * const char* WIFI_SSID = "mi telefono";
 * const char* WIFI_PASS = "password";
*/

// Microrouter Network.
const char* WIFI_SSID = "GL-AR300M-aa7-NOR";
const char* WIFI_PASS = "goodlife";

// Fill with Node IP address, prob dont need anymore since our code constantly monitors the network.
// May need for sending alarm noticiations.
// const char* Node1_IP = 'http://192.168.1.108';
// const char* Node2_IP = 'http://192.168.1.xxx';
// const char* Node3_IP = 'http://192.168.1.xxx';
// const char* Node4_IP = 'http://192.168.1.xxx';
// const char* Node5_IP = 'http://192.168.1.xxx';
// const char* Node6_IP = 'http://192.168.1.xxx';

// Server on port 80.
WebServer server(80);

// ---------
// CONSTANTS
// ---------

// GPIO Pins --> Active Low.

// Trigger Alarm.
const int TRIGGER_ALARM_PIN = 40;

// Turn On Lights.
const int TURN_ON_LIGHTS_PIN = 41;

// Turn Off Alarm.
const int TURN_OFF_ALARM_PIN = 42;

const int LED1 = 16;
const int LED2 = 17;
const int LED3 = 18;

// Turn Off Gadget.
//const byte TURN_OFF_GADGET_PIN = GPIO_NUM_0;

// Switch debounce variables.
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

// Camera node array.
CameraNode cameras[MAX_CAMERAS];

// Number of cameras.
int numCameras = 0;

// Person detection flag.
bool personDetected = false;

// -----------------------------------------------------------------------------------------
// Person Detection Handler.
// -----------------------------------------------------------------------------------------

void handlePersonDetected() {
  // Print person detection notification.
  Serial.println("\n========== PERSON DETECTION NOTIFICATION ==========");
  Serial.println("Time: " + String(millis()));
  Serial.println("Sender IP: " + server.client().remoteIP().toString());
  // Print raw POST data.
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
    
  // Blink LED to Indicate Detection.
  //digitalWrite(LED1, HIGH);
  //delay(100);
  //digitalWrite(LED1, LOW);
    
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
    // Print Ping Request.
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

// *********** HARD WARE TESTING ***********
// - Uncomment code below in checkSwitches() to test hardware.
// - Uncomment Initialize Pins in setup() to test hardware.

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

        // Check turn off gadget switch.
        /*
        if (digitalRead(TURN_OFF_GADGET_PIN) == LOW) {

            // Print notification.
            Serial.println("[INPUT] Turn Off Gadget Switch Activated");

            // Restart gadget.
            Serial.println("Shutting down ESP32...");
            delay(1000);
            ESP.restart();
        }
        */
    }
}

// -----------------------------------------------------------------------------------------
// Setup function that initializes ESP32-CAM.
// -----------------------------------------------------------------------------------------
void setup()
{
  // Initialize pins.
  //pinMode(LED1, OUTPUT);
  pinMode(TRIGGER_ALARM_PIN, INPUT_PULLUP);
  pinMode(TURN_ON_LIGHTS_PIN, INPUT_PULLUP);
  pinMode(TURN_OFF_ALARM_PIN, INPUT_PULLUP);
  // pinMode(TURN_OFF_GADGET_PIN, INPUT_PULLUP);
  //digitalWrite(LED1, LOW);

  // Start serial communication.
  Serial.begin(115200);
  Serial.println("--------------------------------");
  Serial.println("Starting ESP32-S3 Gadget...");
  Serial.println("--------------------------------");

  // Configure wifi connection.
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  // Wait for wifi to connect.
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
      delay(1000);
      Serial.print(".");
      attempts++;
        
      // Blink LED to show we're trying to connect.
      //digitalWrite(LED1, !digitalRead(LED1));
  }

  // Wifi connection result.
  if (WiFi.status() == WL_CONNECTED) {

      // Turn LED on when connected.  
      //digitalWrite(LED1, HIGH);

      // Print connection success.
      Serial.println("\n----------------------------");
      Serial.println("WiFi Connected Successfully!");
      Serial.print("ESP32-S3 IP Address: ");
      Serial.println(WiFi.localIP());
      Serial.print("Signal Strength (RSSI): ");
      Serial.print(WiFi.RSSI());
      Serial.println(" dBm");
      Serial.println("----------------------------\n");

      // Setup server endpoints.  
      server.on("/person_status", HTTP_GET, handlePersonStatus);
      server.on("/person_detected", HTTP_POST, handlePersonDetected);
      server.on("/ping", HTTP_GET, handlePing);
      server.on("/test_trigger_alarm", HTTP_GET, handleTestTriggerAlarm);

      // Test endpoints.
      server.on("/test_turn_off_alarm", HTTP_GET, handleTestTurnOffAlarm);
      server.on("/test_turn_on_lights", HTTP_GET, handleTestTurnOnLights);
      server.on("/test_turn_off_lights", HTTP_GET, handleTestTurnOffLights);
      server.on("/test_restart_gadget", HTTP_GET, handleTestRestartGadget);
        
      // Start the web server.
      server.begin(); 
      Serial.println("HTTP server started successfully");
      Serial.println("Available endpoints:");
      Serial.println("GET  /person_status - Check person detection status");
      Serial.println("POST /person_detected - Receive person detection notifications");
      Serial.println("GET  /ping - Check connection status");

      // Test endpoints.
      Serial.println("GET  /test_trigger_alarm - Test trigger alarm command");
      Serial.println("GET  /test_turn_off_alarm - Test turn off alarm command");
      Serial.println("GET  /test_turn_on_lights - Test turn on lights command");
      Serial.println("GET  /test_turn_off_lights - Test turn off lights command");
      Serial.println("GET  /test_restart_gadget - Restart gadget");
      Serial.println("--------------------------------");
  } else {
      // Turn LED off if failed.
      //digitalWrite(LED, LOW);

      // Print error.
      Serial.println("\n[ERROR] Failed to connect to WiFi after 30 attempts.");
      Serial.println("Please check your WiFi credentials and router settings.");
      Serial.println("Restarting in 5 seconds...");
      delay(5000);
      ESP.restart();
  }
}

// -----------------------------------------------------------------------------------------
// Main loop that continously listens for client requests.
// -----------------------------------------------------------------------------------------

void loop()
{
  // Check Wi-Fi Connection and Reconnect if Disconnected
  static unsigned long lastWiFiCheck = 0;

  // Check Wi-Fi connection every 10 seconds.
  if (millis() - lastWiFiCheck > 10000) {
      lastWiFiCheck = millis();
      if (WiFi.status() != WL_CONNECTED) {
          Serial.println("[WARNING] Wi-Fi lost! Attempting to reconnect...");
          //digitalWrite(LED, LOW);

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
              //digitalWrite(LED, !digitalRead(LED));
          }

          // Reconnect success.
          if (WiFi.status() == WL_CONNECTED) {
              Serial.println("\nWi-Fi reconnected successfully!");
              //digitalWrite(LED, HIGH);
          } else {
              // Print error and restart.
              Serial.println("\n[ERROR] Failed to reconnect. Restarting...");
              delay(5000);
              ESP.restart();
          }
      }
  }

  // Handle incoming HTTP requests.
  server.handleClient();
    
  // Check Hardware Switches.
  checkSwitches();
    
  // Blink LED occasionally to show the device is running.
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 2000 && WiFi.status() == WL_CONNECTED) {
      //digitalWrite(LED, !digitalRead(LED));
      lastBlink = millis();
  }
}

// -----------------------------------------------------------------
//                      main.ino(Gadget)
// -----------------------------------------------------------------