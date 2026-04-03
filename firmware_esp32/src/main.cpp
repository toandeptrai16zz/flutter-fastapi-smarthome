#include <Arduino.h>
#include <ArduinoJson.h> // Library for JSON parsing
#include <ArduinoOTA.h>
#include <DHT.h>
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <WiFiManager.h>

// --- MQTT ---
const char *mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

// --- GPIO CONTROL TOPIC (NEW 2.0) ---
const char *topic_gpio_control = "smarthome/esp/gpio/control";

// --- SENSOR DHT11 ---
#define DHTPIN D1
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// --- CẢM BIẾN CHUYỂN ĐỘNG PIR & NÚT BẤM (NEW 2.0) ---
#define PIR_PIN D2    // Chân đọc cảm biến PIR
#define BTN1_PIN D3   // Nút bấm vật lý 1 (An toàn vì nút nhả hở mạch lúc boot)
#define BTN2_PIN D4   // Nút bấm vật lý 2
#define RELAY1_PIN D7 // Relay 1 (Dời sang D7)
#define RELAY2_PIN D6 // Relay 2

bool lastPirState = false;
bool relay1State = false;
bool relay2State = false;
bool lastBtn1 = HIGH;
bool lastBtn2 = HIGH;

WiFiClient espClient;
PubSubClient client(espClient);

void setup_wifi() {
  Serial.println("\n--- WiFi Management ---");
  WiFiManager wifiManager;
  if (!wifiManager.autoConnect("SmartHome-Config")) {
    Serial.println("❌ WiFi connection failed! Resetting...");
    delay(3000);
    ESP.restart();
  }
  Serial.println("✅ WiFi connected! IP: " + WiFi.localIP().toString());
}

// --- CALLBACK: XỬ LÝ LỆNH ĐIỀU KHIỂN CHÂN ĐỘNG ---
void callback(char *topic, byte *payload, unsigned int length) {
  Serial.print("📩 Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");

  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, payload, length);

  if (error) {
    Serial.print("JSON Parse failed: ");
    Serial.println(error.c_str());
    return;
  }

  if (String(topic) == topic_gpio_control) {
    int pin = doc["pin"];
    const char *action = doc["action"]; // "on" or "off"

    // Hỗ trợ tất cả chân Pin >= 0
    if (pin >= 0) {
      pinMode(pin, OUTPUT);
      bool state = (String(action) == "on");
      digitalWrite(pin, state ? HIGH : LOW);

      // --- ĐỒNG BỘ TRẠNG THÁI NỘI BỘ (Để nút bấm vật lý không bị lệch pha) ---
      if (pin == RELAY1_PIN) relay1State = state;
      if (pin == RELAY2_PIN) relay2State = state;

      // --- PHẢN HỒI LẠI MQTT (Acknowledgment) ---
      String statusPayload = "{\"relay1\": " + String(relay1State ? "true" : "false") + 
                             ", \"relay2\": " + String(relay2State ? "true" : "false") + "}";
      client.publish("smarthome/devices/esp8266_node1/status", statusPayload.c_str());

      Serial.print("⚡ Action: ");
      Serial.print(action);
      Serial.print(" | GPIO: ");
      Serial.print(pin);
      Serial.print(" | Logic: ");
      Serial.println(state ? "HIGH" : "LOW");
    }
  }
}

void reconnect() {
  int retries = 0;
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
    String clientId = "SmartHome-ESP-" + String(random(0xffff), HEX);

    if (client.connect(clientId.c_str())) {
      Serial.println("CONNECTED");
      // Subscribe vào topic điều khiển chân động duy nhất
      client.subscribe(topic_gpio_control);
      Serial.println("Subscribed to: " + String(topic_gpio_control));
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

  dht.begin();

  pinMode(PIR_PIN, INPUT);
  pinMode(BTN1_PIN, INPUT_PULLUP);
  pinMode(BTN2_PIN, INPUT_PULLUP);
  pinMode(RELAY1_PIN, OUTPUT); // Relay 1
  pinMode(RELAY2_PIN, OUTPUT); // Relay 2

  setup_wifi();

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  // OTA Support
  ArduinoOTA.setHostname("SmartHome-ESP-Dynamic");
  ArduinoOTA.begin();

  Serial.println("🚀 SmartHome Firmware 2.0 (Dynamic GPIO) Ready!");
}

unsigned long lastSensorTime = 0;

void loop() {
  ArduinoOTA.handle();

  if (WiFi.status() != WL_CONNECTED) {
    setup_wifi();
  }

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // --- ĐỌC CẢM BIẾN CHUYỂN ĐỘNG PIR ---
  bool pirState = digitalRead(PIR_PIN);
  if (pirState != lastPirState) {
    lastPirState = pirState;
    if (pirState == HIGH) {
      Serial.println("🏃 Phát hiện chuyển động (PIR Triggered)!");
      String payload = "{\"motion\": true}";
      client.publish("smarthome/sensors/pir/data", payload.c_str());
    }
  }

  // --- ĐỌC NÚT BẤM VẬT LÝ ---
  bool btn1 = digitalRead(BTN1_PIN);
  bool btn2 = digitalRead(BTN2_PIN);

  if (btn1 == LOW && lastBtn1 == HIGH) { // Nhấn nút 1
    relay1State = !relay1State;
    digitalWrite(RELAY1_PIN, relay1State ? HIGH : LOW);
    String payload =
        "{\"relay1\": " + String(relay1State ? "true" : "false") + "}";
    client.publish("smarthome/devices/esp8266_node1/status", payload.c_str());
    Serial.println("🔘 Nút 1 nhấn -> Đảo trạng thái Relay 1");
    delay(200); // Chống dội
  }
  if (btn2 == LOW && lastBtn2 == HIGH) { // Nhấn nút 2
    relay2State = !relay2State;
    digitalWrite(RELAY2_PIN, relay2State ? HIGH : LOW);
    String payload =
        "{\"relay2\": " + String(relay2State ? "true" : "false") + "}";
    client.publish("smarthome/devices/esp8266_node1/status", payload.c_str());
    Serial.println("🔘 Nút 2 nhấn -> Đảo trạng thái Relay 2");
    delay(200); // Chống dội
  }

  lastBtn1 = btn1;
  lastBtn2 = btn2;

  // Đọc cảm biến DHT mỗi 10 giây
  unsigned long now = millis();
  if (now - lastSensorTime > 10000) {
    lastSensorTime = now;

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    if (!isnan(h) && !isnan(t)) {
      String payload = "{\"temperature\": " + String(t, 1) +
                       ", \"humidity\": " + String(h, 1) +
                       ", \"motion\": " + String(pirState ? "true" : "false") +
                       "}";
      client.publish("smarthome/sensors/dht11/data", payload.c_str());
      Serial.println("📤 Published Sensor Data: " + payload);
    }
  }
}