from fastapi import FastAPI, Form, Response
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

project_root = Path(__file__).parent.parent.parent
env_file = project_root / ".env.local"
load_dotenv(env_file)

sys.path.append(str(Path(__file__).parent.parent))
from workers.scraper import WebScraper

app = FastAPI(title="WhatsApp Scraper Bot", version="1.0.0")

account_sid = os.getenv("TWILIO_ACCOUNT_SID")
auth_token = os.getenv("TWILIO_AUTH_TOKEN")
from_number = os.getenv("TWILIO_WHATSAPP_FROM")

twilio_client = None
scraper = WebScraper()

if account_sid and auth_token:
    from twilio.rest import Client
    try:
        twilio_client = Client(account_sid, auth_token)
    except Exception:
        pass

def send_message(to_number: str, message: str):
    if not twilio_client:
        return "test_mode"
    
    if not to_number.startswith("whatsapp:"):
        to_number = f"whatsapp:{to_number}"
    
    try:
        msg = twilio_client.messages.create(
            from_=from_number,
            body=message,
            to=to_number
        )
        return msg.sid
    except Exception:
        return None

def handle_message(phone_number: str, message_text: str):
    message = message_text.strip().lower()
    
    if message in ["hello", "hi", "start"]:
        response = """🤖 WhatsApp Scraper Bot

Commands:
• Send URL to scrape
• 'help' for commands
• 'ping' to test

Example: https://example.com"""
        
    elif message in ["help", "?"]:
        response = """Available commands:
• Send any URL to scrape
• 'ping' - test bot
• 'help' - show commands

Supported sites: news, blogs, e-commerce"""
        
    elif message == "ping":
        response = "🏓 Bot is working!"
        
    elif message_text.strip().lower().startswith(("http://", "https://")):
        send_message(f"whatsapp:{phone_number}", "🚀 Scraping started... Please wait.")
        
        result = scraper.scrape(message_text.strip())
        
        if result["status"] == "success":
            response = f"""✅ Scraping Complete

📄 **{result['title']}**
🔗 {result['url']}

📊 Word count: {result['word_count']}
⏰ {result['scraped_at']}

📝 Content preview:
{result['content'][:500]}...

Send another URL to continue!"""
        else:
            response = f"""❌ Scraping Failed

URL: {result['url']}
Error: {result['error']}

Try a different URL or check if the site is accessible."""
        
        return response
        
    else:
        response = """Unknown command. Try:
• Send a URL
• Type 'help'
• Type 'ping'"""
    
    return response

@app.get("/")
async def root():
    return {"message": "WhatsApp Scraper Bot", "status": "running"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "twilio_configured": bool(twilio_client),
        "credentials_present": bool(account_sid and auth_token)
    }

@app.post("/test-scrape")
async def test_scrape(url: str):
    result = scraper.scrape(url)
    return result

@app.post("/webhook")
async def webhook(From: str = Form(...), Body: str = Form(...)):
    phone_number = From.replace("whatsapp:", "")
    response_message = handle_message(phone_number, Body)
    send_message(From, response_message)
    return Response(status_code=200)

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))
    debug = os.getenv("DEBUG", "true").lower() == "true"
    uvicorn.run("src.api.main:app", host=host, port=port, reload=debug)