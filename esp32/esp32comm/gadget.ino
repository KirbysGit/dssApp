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

#include <WebServer.h>
#include <WiFi.h>
#include <ObjectDetection.h>
#include <HTTPClient.h>

// Add SPIFFS for file storage
#include <SPIFFS.h>

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz wifi band.
const char* WIFI_SSID = "mi telefono";
const char* WIFI_PASS = "password";

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

// Global variables for image handling
uint8_t* lastImage = nullptr;
size_t lastImageSize = 0;
bool personDetected = false;

// Add at the top with other globals
struct CameraNode {
  String url;
  String name;
  unsigned long lastSeen;
};

#define MAX_CAMERAS 5
CameraNode cameras[MAX_CAMERAS];
int numCameras = 0;

// ----
// CODE
// ----

// Handle incoming image POST request
void handleImageUpload() {
  Serial.println("Receiving image upload request...");
  
  // Print all headers for debugging
  for (int i = 0; i < server.headers(); i++) {
    Serial.printf("Header[%s]: %s\n", server.headerName(i).c_str(), server.header(i).c_str());
  }

  String contentType = server.header("Content-Type");
  String contentLength = server.header("Content-Length");

  Serial.println("Headers received:");
  Serial.println("Content-Type: " + contentType);
  Serial.println("Content-Length: " + contentLength);

  // Check for image/jpeg content type (case-insensitive comparison)
  if (contentType.indexOf("image/jpeg") == -1 && contentType.indexOf("IMAGE/JPEG") == -1) {
    Serial.println("Invalid content type: " + contentType);
    server.send(400, "text/plain", "Invalid content type - expected image/jpeg");
    return;
  }

  int contentLen = contentLength.toInt();
  if (contentLen <= 0) {
    Serial.println("Invalid content length: " + contentLength);
    server.send(400, "text/plain", "Invalid content length");
    return;
  }

  Serial.printf("Preparing to receive %d bytes of image data\n", contentLen);

  // Allocate buffer for the image
  uint8_t* buffer = new uint8_t[contentLen];
  if (!buffer) {
    Serial.println("Failed to allocate memory for buffer");
    server.send(500, "text/plain", "Server memory error");
    return;
  }

  // Read the raw POST data
  size_t receivedLength = 0;
  WiFiClient client = server.client();
  unsigned long timeout = millis() + 10000; // 10 second timeout

  while (receivedLength < contentLen && millis() < timeout) {
    if (client.available()) {
      buffer[receivedLength] = client.read();
      receivedLength++;
      
      if (receivedLength % 1024 == 0) {
        Serial.printf("Received %d bytes of %d\n", receivedLength, contentLen);
      }
    }
    yield();
  }

  Serial.printf("Received total: %d bytes\n", receivedLength);

  // Print first few bytes for debugging
  Serial.print("First 32 bytes received: ");
  for (int i = 0; i < min(32, (int)receivedLength); i++) {
    Serial.printf("%02X ", buffer[i]);
  }
  Serial.println();

  // Verify JPEG header (FF D8 FF)
  if (receivedLength >= 3 && 
      buffer[0] == 0xFF && 
      buffer[1] == 0xD8 && 
      buffer[2] == 0xFF) {
    
    // Store the image
    if (lastImage != nullptr) {
      delete[] lastImage;
    }
    
    lastImage = new uint8_t[receivedLength];
    if (lastImage != nullptr) {
      memcpy(lastImage, buffer, receivedLength);
      lastImageSize = receivedLength;
      personDetected = true;
      
      Serial.printf("Successfully stored JPEG image: %d bytes\n", receivedLength);
      server.send(200, "text/plain", "Image received");
    } else {
      Serial.println("Failed to allocate memory for image storage");
      server.send(500, "text/plain", "Server memory error");
    }
  } else {
    Serial.println("Invalid JPEG format");
    server.send(400, "text/plain", "Invalid JPEG format");
  }

  delete[] buffer;
}

// Modified to fetch image from ESP32-CAM
void handleGetLatestImage() {
  Serial.println("Received request for latest image");
  
  if (numCameras == 0) {
    Serial.println("No cameras registered");
    server.send(404, "text/plain", "No cameras registered");
    return;
  }
  
  // Find most recently active camera
  int latestCamera = 0;
  unsigned long mostRecent = 0;
  
  for (int i = 0; i < numCameras; i++) {
    if (cameras[i].lastSeen > mostRecent) {
      mostRecent = cameras[i].lastSeen;
      latestCamera = i;
    }
  }
  
  Serial.printf("Fetching image from camera: %s at %s\n", 
                cameras[latestCamera].name.c_str(), 
                cameras[latestCamera].url.c_str());
  
  HTTPClient http;
  WiFiClient client;
  
  if (!http.begin(client, cameras[latestCamera].url)) {
    Serial.println("Failed to connect to camera");
    server.send(502, "text/plain", "Failed to connect to camera");
    return;
  }
  
  int httpCode = http.GET();
  Serial.printf("Camera response code: %d\n", httpCode);
  
  if (httpCode == HTTP_CODE_OK) {
    String contentType = http.header("Content-Type");
    int len = http.getSize();
    
    Serial.printf("Received image from camera: %d bytes\n", len);
    
    server.sendHeader("Content-Type", contentType);
    server.sendHeader("Cache-Control", "no-cache");
    server.setContentLength(len);
    server.send(200);
    
    // Stream the data
    uint8_t buffer[1024];
    WiFiClient* stream = http.getStreamPtr();
    
    while (http.connected() && (len > 0 || len == -1)) {
      size_t size = stream->available();
      if (size) {
        int c = stream->readBytes(buffer, ((size > sizeof(buffer)) ? sizeof(buffer) : size));
        server.client().write(buffer, c);
        if (len > 0) {
          len -= c;
        }
      }
      yield();
    }
    
    Serial.println("Image sent to client successfully");
  } else {
    Serial.printf("Failed to get image from camera: %d\n", httpCode);
    server.send(502, "text/plain", "Failed to get image from camera");
  }
  
  http.end();
}

// Modified person status endpoint
void handlePersonStatus() {
  String response = "{\"personDetected\": " + String(personDetected ? "true" : "false");
  if (personDetected && lastImage != nullptr) {
    response += ", \"imageAvailable\": true";
  }
  response += "}";
  
  server.send(200, "application/json", response);
  
  // Reset person detected flag after sending status
  personDetected = false;
}

// Modified person detection handler
void handlePersonDetected() {
  Serial.println("Person detection notification received");
  
  // Get the raw POST data
  String postBody = server.arg("plain");
  Serial.println("Received POST data: " + postBody);
  
  // Extract camera_url
  String cameraUrl = "";
  String nodeName = "";
  
  int urlStartQuote = postBody.indexOf("\"camera_url\":\"");
  if (urlStartQuote != -1) {
    urlStartQuote += 13; // Length of "camera_url":\"
    int urlEndQuote = postBody.indexOf("\"", urlStartQuote);
    if (urlEndQuote != -1) {
      cameraUrl = postBody.substring(urlStartQuote, urlEndQuote);
    }
  }
  
  // Extract node name
  int nodeStartQuote = postBody.indexOf("\"node\":\"");
  if (nodeStartQuote != -1) {
    nodeStartQuote += 8; // Length of "node":\"
    int nodeEndQuote = postBody.indexOf("\"", nodeStartQuote);
    if (nodeEndQuote != -1) {
      nodeName = postBody.substring(nodeStartQuote, nodeEndQuote);
    }
  }
  
  Serial.println("Extracted values:");
  Serial.println("Camera URL: [" + cameraUrl + "]");
  Serial.println("Node Name: [" + nodeName + "]");
  
  if (cameraUrl.length() > 0) {
    // Update or add camera to our list
    bool found = false;
    for (int i = 0; i < numCameras; i++) {
      if (cameras[i].name == nodeName) {
        cameras[i].url = cameraUrl;
        cameras[i].lastSeen = millis();
        found = true;
        Serial.printf("Updated existing camera %s with URL %s\n", 
                     nodeName.c_str(), cameraUrl.c_str());
        break;
      }
    }
    
    if (!found && numCameras < MAX_CAMERAS) {
      cameras[numCameras].url = cameraUrl;
      cameras[numCameras].name = nodeName;
      cameras[numCameras].lastSeen = millis();
      numCameras++;
      Serial.printf("Added new camera %s with URL %s, total cameras: %d\n", 
                   nodeName.c_str(), cameraUrl.c_str(), numCameras);
    }
    
    // Set person detected flag
    personDetected = true;
    
    // Blink LED to indicate detection
    digitalWrite(LED, HIGH);
    delay(100);
    digitalWrite(LED, LOW);
    
    // Fetch the latest image from this camera
    HTTPClient http;
    WiFiClient client;
    
    Serial.printf("Fetching image from %s\n", cameraUrl.c_str());
    
    if (http.begin(client, cameraUrl)) {
      int httpCode = http.GET();
      Serial.printf("HTTP GET response code: %d\n", httpCode);
      
      if (httpCode == HTTP_CODE_OK) {
        int len = http.getSize();
        Serial.printf("Image size: %d bytes\n", len);
        
        // Allocate buffer for the image
        if (lastImage != nullptr) {
          delete[] lastImage;
        }
        lastImage = new uint8_t[len];
        
        if (lastImage != nullptr) {
          WiFiClient* stream = http.getStreamPtr();
          size_t written = stream->readBytes(lastImage, len);
          
          if (written == len) {
            lastImageSize = len;
            Serial.printf("Successfully stored image: %d bytes\n", len);
          } else {
            delete[] lastImage;
            lastImage = nullptr;
            Serial.printf("Failed to read complete image. Expected %d bytes, got %d bytes\n", 
                         len, written);
          }
        } else {
          Serial.printf("Failed to allocate %d bytes for image\n", len);
        }
      } else {
        Serial.printf("Failed to fetch image: %d\n", httpCode);
      }
      http.end();
    } else {
      Serial.println("Failed to begin HTTP connection to camera");
    }
    
    server.send(200, "text/plain", "Detection recorded");
  } else {
    Serial.println("Missing or invalid camera URL in request");
    server.send(400, "text/plain", "Missing or invalid camera URL");
  }
}

// Handle direct camera capture
void handleCapture() {
  Serial.println("Receiving captured image...");
  
  WiFiClient client = server.client();
  String contentLength = server.header("Content-Length");
  
  Serial.println("Content-Length: " + contentLength);
  int imageSize = contentLength.toInt();
  
  if (imageSize <= 0) {
    Serial.println("Invalid content length");
    server.send(400, "text/plain", "Invalid content length");
    return;
  }

  // Allocate buffer for the image
  if (lastImage != nullptr) {
    delete[] lastImage;
    lastImage = nullptr;
  }
  
  lastImage = new uint8_t[imageSize];
  if (!lastImage) {
    Serial.println("Failed to allocate memory");
    server.send(500, "text/plain", "Server memory error");
    return;
  }

  // Read the image data
  size_t receivedLength = 0;
  unsigned long timeout = millis() + 10000; // 10 second timeout

  while (receivedLength < imageSize && millis() < timeout) {
    if (client.available()) {
      lastImage[receivedLength] = client.read();
      receivedLength++;
      
      if (receivedLength % 1024 == 0) {
        Serial.printf("Received %d bytes of %d\n", receivedLength, imageSize);
      }
    }
    yield();
  }

  if (receivedLength == imageSize) {
    lastImageSize = imageSize;
    personDetected = true;
    Serial.printf("Successfully received image: %d bytes\n", imageSize);
    server.send(200, "text/plain", "Image received");
  } else {
    delete[] lastImage;
    lastImage = nullptr;
    lastImageSize = 0;
    Serial.println("Failed to receive complete image");
    server.send(400, "text/plain", "Incomplete image data");
  }
}

void setup()
{
  // Initialize LED pin
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  // Start serial communication
  Serial.begin(115200);
  Serial.println("--------------------------------");
  Serial.println("Serial communication starting...");
  Serial.println("--------------------------------");

  // Configure wifi connection.
  WiFi.persistent(false); 
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();  // Disconnect from any previous connections
  delay(1000);  // Give it time to disconnect
  
  Serial.print("Attempting to connect to SSID: ");
  Serial.println(WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  // Wait for wifi to connect
  int attempts = 0;

  // Wait for wifi to connect.
  while (WiFi.status() != WL_CONNECTED && attempts < 30) 
  {
    delay(1000);
    Serial.print("WiFi Status: ");
    switch(WiFi.status()) {
      case WL_IDLE_STATUS:
        Serial.println("IDLE"); break;
      case WL_NO_SSID_AVAIL:
        Serial.println("NO SSID AVAILABLE"); break;
      case WL_SCAN_COMPLETED:
        Serial.println("SCAN COMPLETED"); break;
      case WL_CONNECTED:
        Serial.println("CONNECTED"); break;
      case WL_CONNECT_FAILED:
        Serial.println("CONNECT FAILED"); break;
      case WL_CONNECTION_LOST:
        Serial.println("CONNECTION LOST"); break;
      case WL_DISCONNECTED:
        Serial.println("DISCONNECTED"); break;
      default:
        Serial.println(WiFi.status()); break;
    }
    attempts++;
    
    // Blink LED to show we're trying to connect
    digitalWrite(LED, !digitalRead(LED));
    
    // Every 10 attempts, try reconnecting
    if(attempts % 10 == 0) {
      Serial.println("Trying to reconnect...");
      WiFi.disconnect();
      delay(1000);
      WiFi.begin(WIFI_SSID, WIFI_PASS);
    }
  }

  // Wifi connection result
  if (WiFi.status() == WL_CONNECTED) 
  {
    digitalWrite(LED, HIGH);  // Turn LED on when connected
    Serial.println("\n----------------------------");
    Serial.println("WiFi Connected Successfully!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    Serial.println("----------------------------\n");
    
    // Initialize SPIFFS
    if (!SPIFFS.begin(true)) {
      Serial.println("SPIFFS initialization failed!");
      return;
    }

    // Setup server endpoints
    server.on("/capture", HTTP_POST, handleCapture);
    server.on("/latest_image", HTTP_GET, handleGetLatestImage);
    server.on("/person_status", HTTP_GET, handlePersonStatus);
    server.on("/person_detected", HTTP_POST, handlePersonDetected);
    
    // Start the web server
    server.begin();
    Serial.println("HTTP server started");
    Serial.println("Available endpoints:");
    Serial.println("GET  /latest_image - Get most recent camera image");
    Serial.println("GET  /person_status - Check person detection status");
    Serial.println("POST /person_detected - Receive person detection notifications");
  } 
  // Wifi connection fail.
  else 
  {
    digitalWrite(LED, LOW);  // Turn LED off if failed
    Serial.println("Failed to connect to WiFi after 30 attempts.");
    Serial.println("Please check your WiFi credentials and router settings.");
    Serial.println("Restarting in 5 seconds...");
    delay(5000);
    ESP.restart();
  }
}

// Main loop that continously listens for client requests.
void loop()
{
  // Handle incoming HTTP requests
  server.handleClient();
  
  // Blink LED occasionally to show the device is running
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 2000) {
    digitalWrite(LED, !digitalRead(LED));
    lastBlink = millis();
  }

  // handleImageUpload();

  // FOR FUTURE USE TO SCALE MESSAGE HANDLING...
  // Check for requests from allowed IP addresses
  // if (server.client().remoteIP() in allowedIPs) 
  // {
  //   // Check for request type and call the appropriate handler
  //   if (server.hasArg("type")) 
  //   {
  //     String requestType = server.arg("type");
  //     if (requestType == "image_upload") 
  //     {
  //       handleImageUpload();
  //     } 
      
  //     else if (requestType == "get_data") 
  //     {
  //       handleGetData();
  //     }

  //     else if (requestType == "control_device") 
  //     {
  //       handleControlDevice();
  //     }
      
  //     else if (requestType == "trigger_alarm") 
  //     {
  //       handleTriggerAlarm();
  //     } 
      
  //     else if (requestType == "get_status") 
  //     {
  //       handleGetStatus();
  //     }
  //   }
  // }

  // Check for alarm being triggered from Nodes (active IR sensor or heartbeat dies).
  // if (/* Check pin for active IR sensor or heartbeat signal from a node */) 
  // {
  //   // Trigger alarm (e.g., sound buzzer or send notification)
  //   Serial.println("Alarm triggered from a node!");
  // }

  // Check for image request from mobile app.
  // if (/* Check for image request from mobile app */) 
  // {
  //   // Capture an image using the ESP32-CAM library
  //   // Send the captured image data back to the mobile app
  // }
  
  // Check for turn off alarm from mobile app.
  // if (/* Check for turn off alarm command from mobile app */) 
  // {
  //   // Turn off alarm (e.g., stop buzzer or send notification)
  //   Serial.println("Alarm turned off from mobile app!");
  //   // Write a function to turn off the alarm.
  // }

  // Check for trigger alarm from mobile app.
  // if (/* Check for trigger alarm command from mobile app */) 
  // {
  //   // Trigger alarm (e.g., sound buzzer or send notification)
  //   Serial.println("Alarm triggered from mobile app!");
  //   // Write a function to sound the alarm.
  // }
  
  // Check for Switch 1 (Trigger Alarm) --> Active Low
  // if (digitalRead(TriggerAlarm) == LOW)
  // {
  //   // Send message to all nodes triggering the alarm
  //   // Write a function to sound the alarm.
  // }

  // Check for Switch 2 (Turn on Lights).
  // if (digitalRead(TurnOnLights) == LOW)
  // {
  //   // Send message to all nodes to turn on the lights.
  // }

  // Check for Switch 3 (Turn off Alarm).
  // if (digitalRead(TurnOffAlarm) == LOW)
  // {
  //   // Send message to turn off the alarm.
  //   // Write a function to turn off the alarm.
  // }

  // Check for Switch 4 (Turn off Gadget).
  // if (digitalRead(TurnOffGadget) == LOW)
  // {
  //   // Turn off the Gadget.
  //   // Potentially sleep mode.
  // }
}

// -----------------------------------------------------------------
//                      main.ino(Gadget)
// -----------------------------------------------------------------