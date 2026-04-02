from fastapi import APIRouter
from pydantic import BaseModel
import json
from datetime import datetime
from groq import AsyncGroq

from app.core.config import settings
from app.core.database import db
from app.services.mqtt_service import mqtt
from app.services.websocket_manager import ws_manager
from app.api.routers.devices import FIRMWARE_DEVICE_IDS

router = APIRouter()

class ChatRequest(BaseModel):
    message: str

@router.post("/ai/chat")
async def ai_chat(req: ChatRequest):
    if not hasattr(settings, 'GROQ_API_KEY') or not settings.GROQ_API_KEY:
         return {"reply": "Thiếu API Key", "device_id": "none", "action": False}
    
    groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
    all_devices = await db.db["devices"].find({}, {"_id": 0}).to_list(100)
    
    device_list = []
    for d in all_devices:
        has_fw = d["device_id"] in FIRMWARE_DEVICE_IDS or d.get("gpio_pin") is not None
        room_name = d.get("room", "N/A")
        status_text = "Ready" if has_fw else "No Pin"
        device_list.append(f'- NAME: {d["name"]}, ID: {d["device_id"]}, ROOM: {room_name}, TYPE: {d["type"]}, STATUS: {status_text}')
    
    device_list_str = "\n".join(device_list) if device_list else "None"
    
    system_prompt = f"""Bạn là 'Nhà' - Một quản gia AI Gen Z cực kỳ thông minh, cool ngầu và hiểu chuyện.
Danh sách thiết bị:
{device_list_str}

QUY TẮC ỨNG XỬ & ĐIỀU KHIỂN:
1. NGÔN NGỮ: Nói chuyện như bạn thân, dùng ngôn ngữ Gen Z (vd: 'oke nha', 'đã rõ lền', 'quá là mlem', 'đỉnh nóc kịch trần', 'đã xong ạ'). Ngắn gọn nhưng phải CHẤT.
2. THÔNG MINH ĐỘT XUẤT: Nếu người dùng nói sai ngữ pháp, nói tắt, hoặc nói tiếng Anh bồi (vd: 'light bed', 'bật cái đèn ngủ cái coi', 'tắt mẹ nó đèn đi'), bạn phải tự 'nhảy số' để tìm đúng ID thiết bị dựa trên keyword quan trọng nhất.
3. LOGIC ÁNH XẠ: Luôn ưu tiên kết hợp Tên + Phòng để ra lệnh chính xác 100%.
4. KỶ LUẬT THÉP VỀ THIẾT BỊ: TUYỆT ĐỐI CHỈ điều khiển các thiết bị CÓ MẶT trong "Danh sách thiết bị" ở trên. NẾU người dùng yêu cầu bật/tắt thiết bị KHÔNG CÓ TRONG DANH SÁCH (vd: kêu nóng đòi bật Quạt/Điều hòa nhưng danh sách không có), bạn PHẢI từ chối và trả lời là không có thiết bị đó. KHÔNG ĐƯỢC TỰ BỊA RA device_id!
5. PHẢN HỒI JSON: {{"device_id": ["ID"], "action": true/false, "reply": "Lý do/Lời nhắn Gen Z"}} (NẾU KHÔNG CÓ HÀNH ĐỘNG NÀO HỢP LỆ, device_id TRẢ VỀ [])
ONLY RETURN JSON."""

    try:
        response = await groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "system", "content": system_prompt}, {"role": "user", "content": req.message}],
            temperature=0.3
        )
        data = json.loads(response.choices[0].message.content.replace("```json", "").replace("```", "").strip())
        
        device_ids = data.get("device_id")
        if isinstance(device_ids, str) and device_ids != "none": device_ids = [device_ids]
        elif not isinstance(device_ids, list): device_ids = []
            
        action = data.get("action")
        reply = data.get("reply", "OK")
        
        if device_ids:
            collection = db.db["devices"]
            for d_id in device_ids:
                if d_id == "none": continue
                device = await collection.find_one({"device_id": d_id})
                if device:
                    gpio_pin = device.get("gpio_pin")
                    is_inverted = device.get("is_inverted", False)
                    actual_action = not action if is_inverted else action

                    topic = "smarthome/esp/gpio/control" if gpio_pin is not None else f"smarthome/devices/{d_id}/control"
                    payload = json.dumps({"pin": gpio_pin, "action": "on" if actual_action else "off"}) if gpio_pin is not None else ("ON" if actual_action else "OFF")

                    await mqtt.publish(topic, payload)
                    await collection.update_one({"device_id": d_id}, {"$set": {"status": bool(action), "updated_at": datetime.utcnow()}})
                    await ws_manager.broadcast({"event": "device_update", "data": {"device_id": d_id, "status": bool(action)}})
            
        return {"reply": reply, "device_id": device_ids, "action": action}
    except Exception as e:
        return {"reply": f"Lỗi: {str(e)}", "device_id": "none", "action": False}
