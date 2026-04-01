import google.generativeai as genai
import traceback
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")

genai.configure(api_key=API_KEY)

# Test 1: List available models
print("=== Available models ===")
try:
    for m in genai.list_models():
        if 'generateContent' in [x.name for x in m.supported_generation_methods]:
            print(f"  - {m.name}")
except Exception as e:
    print(f"Error listing models: {e}")
    traceback.print_exc()

# Test 2: Try gemini-2.5-flash
print("\n=== Test gemini-2.5-flash ===")
try:
    model = genai.GenerativeModel('gemini-2.5-flash')
    response = model.generate_content("Xin chào, bạn khỏe không?")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
    traceback.print_exc()

# Test 3: Try gemini-2.0-flash as fallback
print("\n=== Test gemini-2.0-flash ===")
try:
    model = genai.GenerativeModel('gemini-2.0-flash')
    response = model.generate_content("Xin chào, bạn khỏe không?")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
    traceback.print_exc()
