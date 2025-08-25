from fastapi import FastAPI
from fastapi.responses import JSONResponse
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="WhatsApp Scraper Bot",
    description="A professional web scraper controlled via WhatsApp",
    version="1.0.0"
)

@app.get("/")
async def root():
    """
    Root endpoint - just to test that our API is working
    """
    return {
        "message": "WhatsApp Scraper Bot is running!",
        "status": "healthy",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """
    Health check endpoint - AWS and other services use this to check if we're alive
    """
    return {
        "status": "healthy",
        "app_name": os.getenv("APP_NAME", "WhatsApp Scraper Bot"),
        "debug_mode": os.getenv("DEBUG", "false").lower() == "true"
    }

@app.get("/webhook")
async def webhook_verify(hub_mode: str = None, hub_verify_token: str = None, hub_challenge: str = None):
    """
    WhatsApp webhook verification endpoint
    WhatsApp will call this to verify our webhook is real
    """
    if hub_mode == "subscribe" and hub_verify_token == os.getenv("WEBHOOK_VERIFY_TOKEN"):
        print("Webhook verified successfully!")
        return int(hub_challenge)
    else:
        print("Webhook verification failed!")
        return JSONResponse(status_code=403, content={"error": "Verification failed"})

@app.post("/webhook")
async def webhook_handler(request_data: dict):
    """
    WhatsApp webhook handler - this receives messages from WhatsApp
    We'll build this out more later
    """
    print(f"Received webhook data: {request_data}")
    
    return {"status": "received"}

if __name__ == "__main__":
    import uvicorn
    
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    
    print(f"Starting WhatsApp Scraper Bot API on {host}:{port}")
    print(f"Debug mode: {debug}")
    
    uvicorn.run(app, host=host, port=port, reload=debug)