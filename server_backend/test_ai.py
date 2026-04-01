import requests
import json

url = "http://localhost:8000/ai/chat"
headers = {"Content-Type": "application/json"}

tests = [
    "bật đèn phòng khách đi",
    "tắt quạt giùm",
    "ê hôm nay trời nóng quá",
    "bật hết đèn lên đi",
]

for msg in tests:
    print(f"\n--- Test: '{msg}' ---")
    try:
        r = requests.post(url, json={"message": msg}, headers=headers, timeout=30)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            print(f"Reply: {data.get('reply')}")
            print(f"Device: {data.get('device_id')}, Action: {data.get('action')}")
        else:
            print(f"Error: {r.text}")
    except Exception as e:
        print(f"Exception: {e}")
