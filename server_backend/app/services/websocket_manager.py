"""
WebSocket Connection Manager - tách riêng để tránh circular import.
Được import bởi cả main.py và mqtt_service.py.
"""
import json
from typing import List
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        print(f"🔌 WebSocket connected! Total: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        print(f"🔌 WebSocket disconnected. Total: {len(self.active_connections)}")

    async def broadcast(self, message: dict):
        """Gửi JSON tới tất cả Flutter clients đang kết nối"""
        if not self.active_connections:
            return
        text = json.dumps(message, ensure_ascii=False)
        dead = []
        for connection in self.active_connections:
            try:
                await connection.send_text(text)
            except Exception:
                dead.append(connection)
        for d in dead:
            self.disconnect(d)
        if self.active_connections:
            print(f"✅ Broadcast to {len(self.active_connections)} WS clients: {message.get('type','?')}")


# Singleton instance - import file này ở cả main.py lẫn mqtt_service.py
ws_manager = ConnectionManager()
