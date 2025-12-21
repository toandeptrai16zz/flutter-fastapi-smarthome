# System configurations (IP, Port, MQTT Host)
import os

SERVER_HOST = os.getenv("SERVER_HOST", "127.0.0.1")
SERVER_PORT = int(os.getenv("SERVER_PORT", "8000"))
MQTT_BROKER_HOST = os.getenv("MQTT_BROKER_HOST", "mqtt.eclipse.org")
