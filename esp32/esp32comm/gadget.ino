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

// ----
// CODE
// ----

// Handle incoming image POST request
void handleImageUpload() {
  Serial.println("Receiving image upload request...");
  
  // Check for Content-Length header
  if (!server.hasHeader("Content-Length")) {
    Serial.println("No Content-Length header");
    server.send(400, "text/plain", "Missing Content-Length header");
    return;
  }

  size_t contentLength = server.header("Content-Length").toInt();
  Serial.printf("Content Length from header: %d bytes\n", contentLength);
  
  if (contentLength <= 0) {
    Serial.println("Invalid content length");
    server.send(400, "text/plain", "Invalid content length");
    return;
  }

  // Allocate buffer for image data
  uint8_t* buffer = new uint8_t[contentLength];
  if (!buffer) {
    Serial.println("Failed to allocate memory");
    server.send(500, "text/plain", "Server memory error");
    return;
  }

  // Read raw POST data
  size_t receivedLength = 0;
  WiFiClient client = server.client();
  
  // Wait for data to be available
  unsigned long timeout = millis() + 5000; // 5 second timeout
  while (client.connected() && receivedLength < contentLength && millis() < timeout) {
    if (client.available()) {
      buffer[receivedLength++] = client.read();
    }
    yield(); // Allow ESP32 to handle background tasks
  }

  Serial.printf("Actually received: %d bytes\n", receivedLength);

  if (receivedLength > 0) {
    // Print first bytes for debugging
    Serial.print("First 32 bytes: ");
    for (int i = 0; i < min(32, (int)receivedLength); i++) {
      Serial.printf("%02X ", buffer[i]);
    }
    Serial.println();

    // Store the image
    if (lastImage != nullptr) {
      delete[] lastImage;
      lastImage = nullptr;
    }

    lastImage = buffer; // Transfer ownership of buffer
    lastImageSize = receivedLength;

    // Verify JPEG header
    if (lastImageSize >= 3 && lastImage[0] == 0xFF && lastImage[1] == 0xD8 && lastImage[2] == 0xFF) {
      personDetected = true;
      Serial.println("Valid JPEG header found");
      server.send(200, "text/plain", "Image received");
    } else {
      Serial.println("Invalid JPEG header");
      delete[] lastImage;
      lastImage = nullptr;
      lastImageSize = 0;
      server.send(400, "text/plain", "Invalid JPEG format");
    }
  } else {
    delete[] buffer;
    server.send(400, "text/plain", "No data received");
  }
}

// Modified to handle raw binary data
void handleGetLatestImage() {
  if (lastImage != nullptr && lastImageSize > 0) {
    Serial.printf("Serving image of size: %d bytes\n", lastImageSize);
    Serial.print("First 32 bytes of image: ");
    for (int i = 0; i < min(32, (int)lastImageSize); i++) {
      Serial.printf("%02X ", lastImage[i]);
    }
    Serial.println();

    // Set headers for binary data
    server.sendHeader("Content-Type", "image/jpeg");
    server.sendHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    server.sendHeader("Pragma", "no-cache");
    server.sendHeader("Expires", "0");
    
    // Send the response in smaller chunks
    const size_t CHUNK_SIZE = 1024; // Increased chunk size for larger images
    size_t remaining = lastImageSize;
    size_t offset = 0;
    
    server.setContentLength(lastImageSize);
    server.send(200);
    
    while (remaining > 0) {
      size_t chunk = min(CHUNK_SIZE, remaining);
      server.sendContent((char*)(lastImage + offset), chunk);
      remaining -= chunk;
      offset += chunk;
      
      // Debug print for chunks
      Serial.printf("Sent chunk: %d bytes, Remaining: %d bytes\n", chunk, remaining);
      yield(); // Allow the ESP8266 to handle background tasks
    }
    
    Serial.printf("Sent complete image: %d bytes\n", lastImageSize);
  } else {
    Serial.println("No image available to serve");
    server.send(404, "text/plain", "No image available");
  }
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

void handlePersonDetected() {
  Serial.println("Person detected");
  digitalWrite(LED, LOW);
  digitalWrite(LED, HIGH);
  
  server.send(200, "text/plain", "Person detection event received");
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
    server.on("/image_upload", HTTP_POST, handleImageUpload);
    server.on("/latest_image", HTTP_GET, handleGetLatestImage);
    server.on("/person-status", HTTP_GET, handlePersonStatus);
    server.on("/person_detected", HTTP_POST, handlePersonDetected);
    
    // Start the web server
    server.begin();
    Serial.println("HTTP server started");
    Serial.println("Available endpoints:");
    Serial.println("POST /image_upload");
    Serial.println("GET  /latest_image");
    Serial.println("GET  /person-status");
    Serial.println("POST /person_detected");
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
    Serial.println("Device running...");
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