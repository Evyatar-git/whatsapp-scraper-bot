from fastapi import FastAPI, Form, Response, Depends, HTTPException, Request
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from datetime import datetime
from src.config.logging import setup_logging
from src.config.settings import settings
from src.database import get_db, init_database, WeatherData, test_database_connection
from src.models.schemas import WeatherRequest, WeatherResponse, ErrorResponse
from src.services.weather import WeatherService
from sqlalchemy.orm import Session
import logging
from twilio.twiml.messaging_response import MessagingResponse
from twilio.request_validator import RequestValidator
import html

# Setup logging
logger = setup_logging()

# Initialize database
init_database()

app = FastAPI(title="WhatsApp Weather Bot", version="1.0.0")

account_sid = os.getenv("TWILIO_ACCOUNT_SID")
auth_token = os.getenv("TWILIO_AUTH_TOKEN")
from_number = os.getenv("TWILIO_WHATSAPP_FROM")

twilio_client = None
weather_service = WeatherService()

if account_sid and auth_token:
    from twilio.rest import Client
    try:
        twilio_client = Client(account_sid, auth_token)
        logger.info("Twilio client initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Twilio client: {str(e)}")
else:
    logger.warning("Twilio credentials not found, running in test mode")

def send_message(to_number: str, message: str):
    logger.info(f"Sending message to {to_number}, length: {len(message)}")
    
    if not twilio_client:
        logger.info(f"Test mode: message not sent to {to_number}")
        return "test_mode"
    
    if not to_number.startswith("whatsapp:"):
        to_number = f"whatsapp:{to_number}"
    
    try:
        msg = twilio_client.messages.create(
            from_=from_number,
            body=message,
            to=to_number
        )
        logger.info("Message sent successfully", 
                   to_number=to_number, 
                   message_sid=msg.sid)
        return msg.sid
    except Exception as e:
        logger.error("Failed to send message", 
                    to_number=to_number, 
                    error=str(e))
        return None

def handle_message(phone_number: str, message_text: str, db: Session):
    logger.info("Handling message", 
               phone_number=phone_number, 
               message_length=len(message_text))
    
    message = message_text.strip().lower()
    
    if message in ["hello", "hi", "start"]:
        response = """WhatsApp Weather Bot

Commands:
• Send city name for weather (e.g., 'London' or 'New York')
• 'help' for commands
• 'ping' to test

Example: London"""
        
    elif message in ["help", "?"]:
        response = """Available commands:
• Send city name for weather
• 'ping' - test bot
• 'help' - show commands

Supported: Any city worldwide"""
        
    elif message == "ping":
        response = "Weather bot is working!"
        
    else:
        # Treat any other message as a city name
        logger.info("Weather request", 
                   phone_number=phone_number, 
                   city=message_text.strip())
        
        send_message(f"whatsapp:{phone_number}", "Fetching weather data... Please wait.")
        
        try:
            # Validate city name using Pydantic
            weather_request = WeatherRequest(city=message_text.strip())
            
            result = weather_service.get_current_weather(
                city=weather_request.city, 
                db=db
            )
            
            if result["status"] == "success":
                # Store weather data in database
                weather_data = WeatherData(
                    city=result["city"],
                    temperature=result["temperature"],
                    description=result["description"],
                    humidity=result.get("humidity"),
                    feels_like=result.get("feels_like")
                )
                db.add(weather_data)
                db.commit()
                
                response = weather_service.format_weather_message(result)
                logger.info(f"Weather data stored for {result['city']}")
            else:
                response = f"""Weather Error

Could not fetch weather for: {weather_request.city}
Error: {result.get('error', 'Unknown error')}

Try a different city name."""
                
        except ValueError as e:
            response = f"""Invalid Input

Error: {str(e)}

Please send a valid city name (letters only)."""
            logger.warning(f"Invalid city name from {phone_number}: {str(e)}")
        except Exception as e:
            response = "Sorry, an error occurred. Please try again later."
            logger.error(f"Weather request error from {phone_number}: {str(e)}")
    
    logger.info(f"Response prepared for {phone_number}, length: {len(response)}")
    return response

@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "WhatsApp Weather Bot", "status": "running"}

@app.get("/health")
async def health():
    logger.info("Health check requested")
    
    try:
        database_connected = test_database_connection()
        
        health_status = {
            "status": "healthy" if database_connected else "unhealthy",
            "twilio_configured": bool(twilio_client),
            "credentials_present": bool(account_sid and auth_token),
            "database_connected": database_connected,
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info("Health check completed successfully")
        return health_status
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@app.post("/weather", response_model=WeatherResponse)
async def get_weather(request: WeatherRequest, db: Session = Depends(get_db)):
    logger.info(f"Weather API requested for city: {request.city}")
    
    try:
        result = weather_service.get_current_weather(city=request.city, db=db)
        
        if result["status"] == "success":
            data = result["data"]
            weather_data = WeatherData(
                city=data["city"],
                temperature=data["temperature"],
                description=data["description"],
                humidity=data.get("humidity"),
                feels_like=data.get("feels_like")
            )
            db.add(weather_data)
            db.commit()
            
            response = WeatherResponse(
                city=data["city"],
                temperature=data["temperature"],
                description=data["description"],
                humidity=data.get("humidity"),
                feels_like=data.get("feels_like"),
                created_at=weather_data.created_at
            )
            
            logger.info(f"Weather API completed successfully for {request.city}")
            return response
        else:
            logger.error(f"Weather API failed for {request.city}: {result.get('error')}")
            raise HTTPException(
                status_code=400,
                detail=f"Weather data not found for {request.city}: {result.get('error', 'Unknown error')}"
            )
            
    except Exception as e:
        logger.error(f"Weather API error for {request.city}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/webhook")
async def webhook(request: Request, From: str = Form(...), Body: str = Form(...)):
    logger.info(f"Webhook received from {From}, body length: {len(Body)}")
    try:
        # Validate Twilio signature when credentials are configured
        if auth_token:
            try:
                signature = request.headers.get("X-Twilio-Signature", "")
                form_data = dict((await request.form()).items())
                url = str(request.url)
                validator = RequestValidator(auth_token)
                if not validator.validate(url, form_data, signature):
                    logger.warning("Twilio signature validation failed")
                    return Response(status_code=403, content="Forbidden")
            except Exception as e:
                logger.exception(f"Signature validation error: {e}")
                return Response(status_code=403, content="Forbidden")

        message_text = Body.strip()
        message_lower = message_text.lower()

        if message_lower == "ping":
            reply_text = "Weather bot is working!"
        elif message_lower in ["hello", "hi", "start"]:
            reply_text = (
                "WhatsApp Weather Bot\n\n"
                "Commands:\n"
                "• Send city name for weather (e.g., 'London' or 'New York')\n"
                "• 'help' for commands\n"
                "• 'ping' to test\n\n"
                "Example: London"
            )
        elif message_lower in ["help", "?"]:
            reply_text = (
                "Available commands:\n"
                "• Send city name for weather\n"
                "• 'ping' - test bot\n"
                "• 'help' - show commands\n\n"
                "Supported: Any city worldwide"
            )
        else:
            # Full weather flow: validate input, fetch weather, format message
            try:
                weather_request = WeatherRequest(city=message_text)
                result = weather_service.get_current_weather(city=weather_request.city, db=None)
                if result["status"] == "success":
                    reply_text = weather_service.format_weather_message({
                        "status": "success",
                        "data": result["data"]
                    })
                else:
                    reply_text = f"Weather Error: {result.get('error', 'Unknown error')}"
            except ValueError as ve:
                reply_text = f"Invalid Input: {str(ve)}"
            except Exception as e:
                logger.exception(f"Weather fetch error: {str(e)}")
                reply_text = "Sorry, an error occurred fetching the weather. Please try again."

        # Build TwiML safely via Twilio helper to avoid XML issues
        safe_text = html.escape(reply_text)
        resp = MessagingResponse()
        resp.message(safe_text)

        logger.info(f"Webhook processed and replying with TwiML, reply_length={len(safe_text)}")
        return Response(content=str(resp), media_type="application/xml", status_code=200)

    except Exception as e:
        logger.exception(f"Webhook error: {str(e)}")
        return Response(status_code=500, content="Internal Server Error")

if __name__ == "__main__":
    import uvicorn
    
    logger.info("Starting server", 
               host=settings.api_host, 
               port=settings.api_port, 
               debug=settings.debug)
    uvicorn.run("src.api.main:app", 
               host=settings.api_host, 
               port=settings.api_port, 
               reload=settings.debug)