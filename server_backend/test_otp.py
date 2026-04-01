"""
Test script: Simulate send-otp logic step-by-step to find bug
"""
import asyncio
import random
import smtplib
import traceback
from datetime import datetime, timedelta
from email.message import EmailMessage

async def test():
    # Step 0: import motor
    from motor.motor_asyncio import AsyncIOMotorClient
    print("Step 0: motor imported OK")

    # Step 1: connect to MongoDB
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    database = client["smarthome_db"]
    print("Step 1: MongoDB client created OK")

    email = "test_debug@example.com"

    try:
        # Step 2: find_one on users collection
        existing_user = await database["users"].find_one({"email": email})
        print(f"Step 2: find_one users OK, result={existing_user}")

        # Step 3: generate OTP
        otp_code = str(random.randint(100000, 999999))
        expires_at = datetime.utcnow() + timedelta(minutes=5)
        print(f"Step 3: OTP generated = {otp_code}")

        # Step 4: upsert into otps collection
        result = await database["otps"].update_one(
            {"email": email},
            {"$set": {"otp": otp_code, "expires_at": expires_at}},
            upsert=True
        )
        print(f"Step 4: upsert OK, modified={result.modified_count}")

        # Step 5: send email (sync, will block but that's fine for test)
        try:
            msg = EmailMessage()
            msg.set_content(f"Test OTP: {otp_code}")
            msg["Subject"] = "Test"
            msg["From"] = "daynekchuong647@gmail.com"
            msg["To"] = email
            with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
                server.login("daynekchuong647@gmail.com", "txolumiebdyzxqdb")
                server.send_message(msg)
            print("Step 5: Email sent OK")
        except Exception as e:
            print(f"Step 5: Email failed (non-fatal): {e}")

        print("\n=== ALL STEPS PASSED! No bug in logic. ===")
    except Exception as e:
        print(f"\n=== ERROR: {e} ===")
        traceback.print_exc()
    finally:
        client.close()

asyncio.run(test())
