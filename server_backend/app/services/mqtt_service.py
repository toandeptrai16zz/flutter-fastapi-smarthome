# MQTT Connection Service
import paho.mqtt.client as mqtt
from app.core.config import MQTT_BROKER_HOST

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
    else:
        print(f"Failed to connect, return code {rc}\n")

def get_mqtt_client():
    client = mqtt.Client()
    client.on_connect = on_connect
    client.connect(MQTT_BROKER_HOST, 1883, 60)
    return client
