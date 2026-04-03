from datetime import datetime, timedelta
import jwt
import bcrypt
from app.core.config import settings

# JWT_SECRET_KEY nên là một chuỗi ngẫu nhiên dài, độc lập với AI API key
SECRET_KEY = settings.JWT_SECRET_KEY if settings.JWT_SECRET_KEY else "smarthome_jwt_fallback_key_change_in_production"
ALGORITHM = "HS256"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception as e:
        print(f"Lỗi kiểm tra mật khẩu: {e}")
        return False

def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=7)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
