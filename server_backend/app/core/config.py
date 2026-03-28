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

    class Config:
        env_file = ".env"

settings = Settings()
