#include <Arduino.h>
#include <DHT.h>
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <WiFiManager.h>
#include <ArduinoOTA.h> // Hỗ trợ nạp code không dây OTA

// --- MQTT ---
const char *mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

// --- CẢM BIẾN DHT11 ---
#define DHTPIN D1 // Cắm chân DATA của DHT11 vào D1
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// --- LED ---
#define LED1_PIN D2
#define LED2_PIN D5

const char *topic_led1 = "smarthome/devices/led_1/control";
const char *topic_led2 = "smarthome/devices/led_2/control";

WiFiClient espClient;
PubSubClient client(espClient);

void setup_wifi() {
  Serial.println("\n--- WiFi Management ---");
  WiFiManager wifiManager;

  // Tự động kết nối WiFi cũ.
  // Nếu không thấy, nó sẽ phát AP tên "SmartHome-Config" pass trống
  if (!wifiManager.autoConnect("SmartHome-Config")) {
    Serial.println("❌ Lỗi kết nối WiFi! Reset sau 3 giây...");
    delay(3000);
    ESP.restart();
  }

  Serial.println("✅ WiFi connected!");
}

void callback(char *topic, byte *payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("Message: ");
  Serial.println(message);

  if (String(topic) == topic_led1) {
    digitalWrite(LED1_PIN, message == "ON" ? HIGH : LOW);
    Serial.println(message == "ON" ? "-> Đèn Phòng Khách BẬT"
                                   : "-> Đèn Phòng Khách TẮT");
  }

  if (String(topic) == topic_led2) {
    digitalWrite(LED2_PIN, message == "ON" ? HIGH : LOW);
    Serial.println(message == "ON" ? "-> Đèn Phòng Ngủ BẬT"
                                   : "-> Đèn Phòng Ngủ TẮT");
  }
}

void reconnect() {
  int retries = 0;
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
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
      if (retries > 12) {
        Serial.println("Timeout! Restarting...");
        ESP.restart();
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  randomSeed(micros());

  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);

  dht.begin();

  setup_wifi();

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

unsigned long lastSensorTime = 0;

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    setup_wifi();
  }

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();
  if (now - lastSensorTime > 5000) {
    lastSensorTime = now;

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    if (isnan(h) || isnan(t)) {
      Serial.println("❌ Lỗi đọc dữ liệu từ cảm biến DHT!");
      return;
    }

    String payload = "{\"temperature\": " + String(t, 1) +
                     ", \"humidity\": " + String(h, 1) + "}";
    if (client.publish("smarthome/sensors/dht11/data", payload.c_str())) {
      Serial.println("📤 Published DHT: " + payload);
    }
  }
}