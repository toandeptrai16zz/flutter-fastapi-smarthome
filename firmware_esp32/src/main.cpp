#include <Arduino.h>
#include <ESP8266WiFi.h>      
#include <ESP8266HTTPClient.h> 
#include <WiFiClient.h>
#include <ArduinoJson.h>

const char* ssid = "538DC0 101 102";     
const char* password = "0989533806";    
String serverUrl = "http://192.168.0.108:8000/device/led_1"; 


#define LED_PIN 2 

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH); 

  WiFi.begin(ssid, password);
  Serial.print("Dang ket noi WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClient client; // <--- ESP8266 cần cái này
    HTTPClient http;

    // Bắt đầu kết nối
    http.begin(client, serverUrl); 
    
    int httpCode = http.GET();

    if (httpCode > 0) {
      String payload = http.getString();
      
      // Phân tích JSON
      DynamicJsonDocument doc(1024);
      deserializeJson(doc, payload);
      bool status = doc["status"];

      if (status) {
        digitalWrite(LED_PIN, LOW); 
        Serial.println("LED: ON");
      } else {
        digitalWrite(LED_PIN, HIGH);
        Serial.println("LED: OFF");
      }
    } else {
      Serial.printf("Lỗi HTTP: %d\n", httpCode);
    }
    http.end();
  }
  delay(1000);
}