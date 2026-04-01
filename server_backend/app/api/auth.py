from fastapi import APIRouter, HTTPException, BackgroundTasks, status
from app.models.user import UserCreate, UserLogin, SendOTPRequest
from app.core.security import get_password_hash, verify_password, create_access_token
from app.core.database import db
from datetime import datetime, timedelta
import random
import smtplib
from email.message import EmailMessage

router = APIRouter()

# --- CẤU HÌNH BẮN EMAIL NẾU BẠN MUỐN DÙNG THẬT ---
# Thay thế bằng email và mật khẩu ứng dụng (App Password) thật của bạn
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 465
SMTP_USER = "daynekchuong647@gmail.com"  # FIXME: Đổi email của bạn
SMTP_PASS = "txolumiebdyzxqdb"      # FIXME: Đổi Mật khẩu ứng dụng của bạn

def send_email_sync(to_email: str, otp_code: str):
    try:
        msg = EmailMessage()
        msg.set_content(f"CHÀO MỪNG BẠN ĐẾN VỚI AIoT SMARTHOME\n\nMã xác thực (OTP) của bạn là: {otp_code}\nMã có hiệu lực trong 5 phút.\nTuyệt đối không chia sẻ mã này cho ai.")
        msg["Subject"] = "Mã xác thực đăng ký tài khoản AIoT SmartHome"
        msg["From"] = SMTP_USER
        msg["To"] = to_email

        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SMTP_USER, SMTP_PASS)
            server.send_message(msg)
        print(f"✅ Đã gửi email chứa mã {otp_code} tới {to_email}")
    except Exception as e:
        print(f"⚠️ Không thể gửi email thực tế, cần config SMTP trong app/api/auth.py: {e}")
        print(f"📝 OTP CHO {to_email} LÀ: {otp_code}")

@router.post("/send-otp")
async def send_otp(request: SendOTPRequest, background_tasks: BackgroundTasks):
    email = request.email
    # Kiểm tra xem email đã tồn tại trong users chưa
    existing_user = await db.db["users"].find_one({"email": email})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email này đã được đăng ký.")

    # Sinh mã 6 số
    otp_code = str(random.randint(100000, 999999))
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    # Lưu vào database collection `otps` (upsert để ghi đè mã cũ nếu có)
    await db.db["otps"].update_one(
        {"email": email},
        {"$set": {"otp": otp_code, "expires_at": expires_at}},
        upsert=True
    )

    # Gửi email chạy dưới background
    background_tasks.add_task(send_email_sync, email, otp_code)
    
    return {"message": "Đã tạo mã OTP thành công. Vui lòng kiểm tra email của bạn."}

@router.post("/register")
async def register(user_data: UserCreate):
    # Kiểm tra OTP
    otp_record = await db.db["otps"].find_one({"email": user_data.email})
    
    if not otp_record:
        raise HTTPException(status_code=400, detail="Email chưa được yêu cầu OTP.")
    
    if otp_record["otp"] != user_data.otp_code:
        raise HTTPException(status_code=400, detail="Mã OTP không chính xác.")
        
    if otp_record["expires_at"] < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Mã OTP đã hết hạn (5 phút).")

    # Xóa OTP đi sau khi dùng
    await db.db["otps"].delete_one({"email": user_data.email})

    # Hash pass và tạo user
    hashed_password = get_password_hash(user_data.password)
    new_user = {
        "email": user_data.email,
        "full_name": user_data.full_name,
        "hashed_password": hashed_password,
        "is_active": True,
        "created_at": datetime.utcnow()
    }
    
    result = await db.db["users"].insert_one(new_user)
    
    # Tạo JWT ngay lập tức cho đăng nhập thẳng
    access_token = create_access_token(data={"sub": user_data.email})
    
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user_id": str(result.inserted_id),
        "email": user_data.email,
        "full_name": user_data.full_name,
        "message": "Đăng ký thành công"
    }

@router.post("/login")
async def login(credentials: UserLogin):
    user = await db.db["users"].find_one({"email": credentials.email})
    if not user:
         raise HTTPException(status_code=400, detail="Email hoặc Mật khẩu không đúng")
         
    if not verify_password(credentials.password, user["hashed_password"]):
         raise HTTPException(status_code=400, detail="Email hoặc Mật khẩu không đúng")

    access_token = create_access_token(data={"sub": user["email"]})
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "email": user["email"],
        "full_name": user.get("full_name", "")
    }
