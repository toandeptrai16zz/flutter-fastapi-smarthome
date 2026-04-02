/*
 * ============================================
 *  NexHome - ESP32-CAM Firmware v2.0
 *  - Auto-publish IP qua MQTT
 *  - Điều khiển Flash LED từ xa
 *  - MJPEG Stream trên port 81
 * ============================================
 *  BOARD: AI Thinker ESP32-CAM
 *  Chọn trong Arduino IDE: Tools -> Board -> AI Thinker ESP32-CAM
 *
 *  CÁCH NẠP:
 *  1. Mở file này trong Arduino IDE (hoặc PlatformIO)
 *  2. Cài thư viện: PubSubClient, ArduinoJson, WiFiManager (by tzapu)
 *  3. Chọn Board "AI Thinker ESP32-CAM"
 *  4. Nối GPIO0 -> GND, nhấn Reset, Upload
 *  5. Tháo dây GPIO0, nhấn Reset -> Chạy!
 *  6. Lần đầu: Kết nối WiFi "NexHome-CAM-Config" để cấu hình mạng
 * ============================================
 */

#include "esp_camera.h"
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <WiFi.h>
#include <WiFiManager.h> // Thư viện WiFiManager cho ESP32

// ========== CẤU HÌNH MQTT ==========
const char *mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char *topic_camera_ip = "smarthome/camera/ip";
const char *topic_camera_flash = "smarthome/camera/flash";

// ========== CHÂN CAMERA AI-THINKER ==========
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

// Flash LED trên board ESP32-CAM (GPIO 4)
#define FLASH_LED_PIN 4

WiFiClient espClient;
PubSubClient mqttClient(espClient);
WiFiServer streamServer(81);

// ========== HÀM KHỞI TẠO CAMERA ==========
bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // Chất lượng hình ảnh
  if (psramFound()) {
    config.frame_size = FRAMESIZE_VGA; // 640x480 - cân bằng chất lượng/tốc độ
    config.jpeg_quality = 12;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_QVGA; // 320x240 nếu không có PSRAM
    config.jpeg_quality = 15;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("❌ Camera init failed! Error: 0x%x\n", err);
    return false;
  }
  Serial.println("✅ Camera khởi tạo thành công!");
  return true;
}

// ========== KẾT NỐI WIFI BẰNG WiFiManager (ĐỘNG) ==========
void setupWiFi() {
  Serial.println("\n--- WiFi Management (Dynamic) ---");
  WiFiManager wifiManager;

  // Timeout 3 phút nếu không ai config thì restart
  wifiManager.setConfigPortalTimeout(180);

  // Phát WiFi riêng tên "NexHome-CAM-Config" để cấu hình
  if (!wifiManager.autoConnect("NexHome-CAM-Config")) {
    Serial.println("❌ WiFi connection failed! Restarting...");
    delay(3000);
    ESP.restart();
  }

  WiFi.setSleep(false); // Tắt sleep để stream mượt
  Serial.println("✅ WiFi connected!");
  Serial.print("📍 IP Address: ");
  Serial.println(WiFi.localIP());
}

// ========== MQTT CALLBACK - NHẬN LỆNH FLASH ==========
void mqttCallback(char *topic, byte *payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.printf("📩 MQTT [%s]: %s\n", topic, message.c_str());

  if (String(topic) == topic_camera_flash) {
    if (message == "ON" || message == "on") {
      digitalWrite(FLASH_LED_PIN, HIGH);
      Serial.println("💡 FLASH LED: BẬT SÁNG CHOÁNG!");
    } else {
      digitalWrite(FLASH_LED_PIN, LOW);
      Serial.println("💡 FLASH LED: TẮT");
    }
  }
}

// ========== KẾT NỐI MQTT & GỬI IP ==========
void connectMQTT() {
  int retries = 0;
  while (!mqttClient.connected() && retries < 5) {
    Serial.print("🔌 Connecting MQTT...");
    String clientId = "NexHome-CAM-" + String(random(0xffff), HEX);

    if (mqttClient.connect(clientId.c_str())) {
      Serial.println(" CONNECTED!");

      // Subscribe nhận lệnh bật/tắt Flash
      mqttClient.subscribe(topic_camera_flash);
      Serial.println("📡 Subscribed: " + String(topic_camera_flash));

      // >>> GỬI IP ĐỘNG LÊN SERVER <<<
      StaticJsonDocument<200> doc;
      doc["ip"] = WiFi.localIP().toString();
      doc["stream_port"] = 81;

      char buffer[200];
      serializeJson(doc, buffer);
      mqttClient.publish(topic_camera_ip, buffer);
      Serial.println("📸 Đã gửi IP Camera lên MQTT: " +
                     WiFi.localIP().toString());

    } else {
      Serial.printf(" failed (rc=%d), retry in 3s...\n", mqttClient.state());
      delay(3000);
      retries++;
    }
  }
}

// ========== MJPEG STREAM HANDLER ==========
void handleStream() {
  WiFiClient client = streamServer.available();
  if (!client)
    return;

  Serial.println("🎬 Client kết nối xem Camera Stream!");

  // Gửi HTTP header cho MJPEG stream
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: multipart/x-mixed-replace; boundary=frame");
  client.println("Access-Control-Allow-Origin: *");
  client.println();

  while (client.connected()) {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("⚠️ Camera capture failed");
      break;
    }

    client.printf(
        "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n",
        fb->len);
    client.write(fb->buf, fb->len);
    client.println();

    esp_camera_fb_return(fb);

    if (!client.connected())
      break;
    delay(30); // ~30 FPS
  }

  Serial.println("🎬 Client ngắt kết nối Stream.");
}

// ========== SETUP ==========
void setup() {
  Serial.begin(115200);
  Serial.println("\n🚀 NexHome ESP32-CAM v2.0 Starting...");

  // Cấu hình Flash LED
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);

  // Khởi tạo Camera
  if (!initCamera()) {
    Serial.println("❌ Camera init failed! Halting.");
    while (1)
      delay(1000);
  }

  // Kết nối WiFi
  setupWiFi();

  // Cấu hình MQTT
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
  connectMQTT();

  // Bắt đầu Stream Server trên port 81
  streamServer.begin();
  Serial.println("🎥 MJPEG Stream sẵn sàng tại: http://" +
                 WiFi.localIP().toString() + ":81/stream");
  Serial.println("================================================");
  Serial.println("  NexHome ESP32-CAM Ready! 📸");
  Serial.println("================================================");
}

// ========== LOOP ==========
unsigned long lastMqttReconnect = 0;
unsigned long lastIpBroadcast = 0;

void loop() {
  // Duy trì kết nối MQTT
  if (!mqttClient.connected()) {
    unsigned long now = millis();
    if (now - lastMqttReconnect > 10000) {
      lastMqttReconnect = now;
      connectMQTT();
    }
  }
  mqttClient.loop();

  // Gửi lại IP mỗi 5 phút (phòng trường hợp Server restart)
  unsigned long now = millis();
  if (now - lastIpBroadcast > 300000) { // 5 phút
    lastIpBroadcast = now;
    StaticJsonDocument<200> doc;
    doc["ip"] = WiFi.localIP().toString();
    doc["stream_port"] = 81;
    char buffer[200];
    serializeJson(doc, buffer);
    mqttClient.publish(topic_camera_ip, buffer);
    Serial.println("📸 Re-broadcast IP Camera: " + WiFi.localIP().toString());
  }

  // Xử lý Stream
  handleStream();
}
