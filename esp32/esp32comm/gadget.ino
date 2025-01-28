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
#include <esp32cam.h>
#include <ObjectDetection.h>
#include <HTTPClient.h>

// PLEASE FILL IN PASSWORD AND WIFI RESTRICTIONS.
// MUST USE 2.4GHz wifi band.
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

// ----
// CODE
// ----

// Handle incoming image POST request.
// void handleImageUpload() 
// {
//   // Example using HTTP GET request:
//   HTTPClient http;
//   http.begin("http://192.168.1.120/image_upload");

//   // String payload = http.getString();
//   // Serial.println(payload);
//   // uint8_t* imageData = (uint8_t*)payload.c_str();
//   // size_t imageSize = payload.length();

//   String IncomingData = server.arg("text/plain");
//   uint8_t* imageData = (uint8_t*)IncomingData.c_str();
//   size_t imageSize = server.arg("text/plain").length();

//   if (imageSize > PSRAM_BUF_SIZE) 
//   {
//     server.send(413, "text/plain", "Image too large to fit in PSRAM");
//     return;
//   }

//   // Allocate PSRAM buffer if not already allocated.
//   if (!psramBuffer) 
//   {
//     psramBuffer = (uint8_t*)ps_malloc(PSRAM_BUF_SIZE);
//     if (!psramBuffer) 
//     {
//       server.send(500, "text/plain", "Failed to allocate PSRAM");
//       return;
//     }
//   }

//   // Copy the image data to PSRAM.
//   memcpy(psramBuffer, imageData, imageSize);

//   // Debug print
//   Serial.printf("Captured image size: %d bytes\n", imageSize);
//   Serial.printf("psramBuffer: %p\n", psramBuffer);

//   // Send success response.
//   server.send(200, "text/plain", "Image received and stored");

//   bool personDetected = ObjectDetection::detectPerson(psramBuffer, imageSize);

//   if(personDetected)
//   {
//     Serial.println("Person detected!");
//     Serial.println("Sounding alarms and sending notifications...");
//     // Sound alarm.
//     // Send notification.
//   }
//   else
//   {
//     Serial.println("Motion detected, no person found in the area.");
//   }

//   // Free the allocated memory to avoid leaks.
//   if (psramBuffer) 
//   {
//     free(psramBuffer);
//     psramBuffer = nullptr;  // Set pointer to nullptr after freeing
//     Serial.println("PSRAM memory deallocated.");
//   }


//   // Get image data from the request.
//   // String IncomingData = server.arg("image/jpeg");
//   // uint8_t* imageData = (uint8_t*)IncomingData.c_str();
//   // size_t imageSize = server.arg("image/jpeg").length();
// }

void personDetected()
{
  // Example using HTTP GET request:
  HTTPClient http;
  // http.begin("http://192.168.8.213/person_detected");

  Serial.println("Person detected");
  digitalWrite(LED, LOW);
  digitalWrite(LED, HIGH);
  
  // Send notification to Node's to sound alarm.
  // Send notification to mobile app.
}

void setup()
{
  Serial.begin(115200);
  Serial.println("--------------------------------");
  Serial.println("Serial communication starting...");
  Serial.println("--------------------------------");

  // Configure wifi connection.
  WiFi.persistent(false); 
  WiFi.mode(WIFI_STA); // Wifi to station mode.
  WiFi.begin(WIFI_SSID, WIFI_PASS); // Connect to the wifi network.

  // Wifi attempt tracker, ensure fast connection.
  int attempts = 0;

  // Wait for wifi to connect.
  while (WiFi.status() != WL_CONNECTED && attempts < 30) 
  {
    Serial.print("WiFi Status: ");
    Serial.println(WiFi.status());
    Serial.println("Connecting ESPE32-CAM to wifi...");
    delay(2000);
    attempts++;
  }

  // Wifi connection success.
  if (WiFi.status() == WL_CONNECTED) 
  {
    Serial.print("Connected! IP Address: ");
    Serial.println(WiFi.localIP());
  } 
  
  // Wifi connection fail.
  else 
  {
    Serial.println("Failed to connect to WiFi. Restarting...");
    ESP.restart();  // Restart ESP32 if connection fails
  }

  Serial.print("http://");
  Serial.println(WiFi.localIP());

  // Start the server and define the endpoint for image uploads.
  // server.on("/image_upload", HTTP_POST, handleImageUpload);
  server.on("/person_detected", HTTP_POST, personDetected);
  server.begin();
  Serial.println("HTTP server started");

  // pinMode(TriggerAlarm, INPUT_PULLUP);
  // pinMode(TurnOnLights, INPUT_PULLUP);
  // pinMode(TurnOffAlarm, INPUT_PULLUP);
  // pinMode(TurnOffGadget, INPUT_PULLUP);
  // Initialize Passive IR sensor pin
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  if (!psramFound()) 
  {
    Serial.println("PSRAM not found");
    ESP.restart();
  }
  else
  {
    Serial.println("We have PSRAM!!");
  }
}

// Main loop that continously listens for client requests.
void loop()
{
  Serial.println("Test working...");
  delay(2000);

  // Handle incoming HTTP requests.
  server.handleClient();

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