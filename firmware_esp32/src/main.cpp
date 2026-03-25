#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>

// --- WIFI ---
const char *ssid = "538DC0 101 102";
const char *password = "0989533806";

// --- MQTT ---
const char *mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

// --- LED ---
#define LED1_PIN D2
#define LED2_PIN D5

const char *topic_led1 = "smarthome/devices/led_1/control";
const char *topic_led2 = "smarthome/devices/led_2/control";

WiFiClient espClient;
PubSubClient client(espClient);

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected!");
}

void callback(char *topic, byte *payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("Message: ");
  Serial.println(message);

  if (String(topic) == topic_led1) {
    // Nút "Smart AC" trên App => Đèn Phòng Khách (LED 1 / D2)
    digitalWrite(LED1_PIN, message == "ON" ? HIGH : LOW);
    Serial.println(message == "ON" ? "-> Đèn Phòng Khách BẬT" : "-> Đèn Phòng Khách TẮT");
  }

  if (String(topic) == topic_led2) {
    // Nút "Smart Light" trên App => Đèn Phòng Ngủ (LED 2 / D5)
    digitalWrite(LED2_PIN, message == "ON" ? HIGH : LOW);
    Serial.println(message == "ON" ? "-> Đèn Phòng Ngủ BẬT" : "-> Đèn Phòng Ngủ TẮT");
  }
}

void reconnect() {
  int retries = 0;
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
    // Random Client ID tránh conflict
    String clientId = "SmartHome-ESP-" + String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("CONNECTED");
      client.subscribe(topic_led1);
      client.subscribe(topic_led2);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 5s");
      delay(5000);
      retries++;
      if (retries > 12) { // 1 phút không được thì reset
        Serial.println("Timeout! Restarting...");
        ESP.restart();
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  randomSeed(micros()); // Seed cho random ID

  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);

  setup_wifi();

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    setup_wifi();
  }
  
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}