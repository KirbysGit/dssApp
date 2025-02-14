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
//
// Note(1): ChatGPT aided in the development of this code.
// Note(2): To run this code in arduino ide, please use , set baud
// rate to 115200 to analyze serial communication, and enter both
// the password and wifi to work within the network.
// -----------------------------------------------------------------

// Imports.
#include <WebServer.h>
#include <WiFi.h>
#include <ObjectDetection.h>
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
// const byte TriggerAlarm = GPIO_NUM_24;
// const byte TurnOnLights = GPIO_NUM_25;
// const byte TurnOffAlarm = GPIO_NUM_26;
// const byte TurnOffGadget = GPIO_NUM_27;
const int LED = 21;

// PSRAM buffer.
// uint8_t* psramBuffer = nullptr;
// const int PSRAM_BUF_SIZE = 500 * 1024; // Adjust as needed

// For future use to scale message handling.
// enum RequestType {
//   REQUEST_TYPE_IMAGE_UPLOAD,
//   REQUEST_TYPE_GET_DATA,
//   REQUEST_TYPE_CONTROL_DEVICE,
//   REQUEST_TYPE_TRIGGER_ALARM,
//   REQUEST_TYPE_GET_STATUS
// };
// const IPAddress allowedIPs[] = {
//   IPAddress(192, 168, 1, 100),
//   IPAddress(192, 168, 1, 101),
//   // ... add other allowed IP addresses
// };

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

  // Update or add camera to our list
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

  // Add new camera to our list.
  if (!found && numCameras < MAX_CAMERAS) {
      cameras[numCameras].url = cameraUrl;
      cameras[numCameras].name = nodeName;
      cameras[numCameras].lastSeen = millis();
      numCameras++;
      Serial.printf("Added new camera %s with URL %s, total cameras: %d\n", 
                  nodeName, cameraUrl, numCameras);
  }

  // Set person detected flag
  personDetected = true;
    
  // Create response JSON with camera information
  String response = "{";
  response += "\"status\":\"success\",";
  response += "\"message\":\"Detection recorded\",";
  response += "\"camera_url\":\"" + String(cameraUrl) + "\",";
  response += "\"node\":\"" + String(nodeName) + "\",";
  response += "\"timestamp\":\"" + String(timestamp ? timestamp : "") + "\"";
  response += "}";
  
  // Send response.
  server.send(200, "application/json", response);
    
  // Blink LED to indicate detection.
  digitalWrite(LED, HIGH);
  delay(100);
  digitalWrite(LED, LOW);
    
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
    
  // Iterate through cameras and add to response.
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
// Setup function that initializes ESP32-CAM.
// -----------------------------------------------------------------------------------------

void setup()
{
  // Initialize LED pin.
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

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
      digitalWrite(LED, !digitalRead(LED));
  }

  // Wifi connection result.
  if (WiFi.status() == WL_CONNECTED) {

      // Turn LED on when connected.  
      digitalWrite(LED, HIGH);

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
        
      // Start the web server.
      server.begin(); 
      Serial.println("HTTP server started successfully");
      Serial.println("Available endpoints:");
      Serial.println("GET  /person_status - Check person detection status");
      Serial.println("POST /person_detected - Receive person detection notifications");
      Serial.println("GET  /ping - Check connection status");
      Serial.println("--------------------------------");
  } else {
      // Turn LED off if failed.
      digitalWrite(LED, LOW);

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
          digitalWrite(LED, LOW);

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
              digitalWrite(LED, !digitalRead(LED));
          }

          // Reconnect success.
          if (WiFi.status() == WL_CONNECTED) {
              Serial.println("\nWi-Fi reconnected successfully!");
              digitalWrite(LED, HIGH);
          } else {
              // Print error and restart.
              Serial.println("\n[ERROR] Failed to reconnect. Restarting...");
              delay(5000);
              ESP.restart();
          }
      }
  }

  // Handle incoming HTTP requests
  server.handleClient();
    
  // Blink LED occasionally to show the device is running
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 2000 && WiFi.status() == WL_CONNECTED) {
      digitalWrite(LED, !digitalRead(LED));
      lastBlink = millis();
  }
}

// -----------------------------------------------------------------
//                      main.ino(Gadget)
// -----------------------------------------------------------------