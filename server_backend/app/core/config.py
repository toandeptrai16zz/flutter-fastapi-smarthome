import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGODB_URL: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "smarthome_db"
    MQTT_BROKER_URL: str = "broker.hivemq.com"
    MQTT_BROKER_PORT: int = 1883
    MQTT_USERNAME: str = ""
    MQTT_PASSWORD: str = ""
    GEMINI_API_KEY: str = ""
    GROQ_API_KEY: str = ""
    JWT_SECRET_KEY: str = ""  # ✅ Thêm biến riêng cho JWT

    # ESP32/NodeMCU Pin Pool (Mapping Label -> GPIO Number)
    ESP32_PIN_MAP: dict = {
        "D1 (GPIO 5) - Cảm biến DHT11": 5,
        "D2 (GPIO 4) - Cảm biến PIR": 4,
        "D3 (GPIO 0) - Nút cứng 1": 0,
        "D4 (GPIO 2) - Nút cứng 2": 2,
        "D5 (GPIO 14)": 14,
        "D6 (GPIO 12)": 12,
        "D7 (GPIO 13)": 13,
        "D8 (GPIO 15)": 15,
    }

    class Config:
        env_file = ".env"

settings = Settings()
