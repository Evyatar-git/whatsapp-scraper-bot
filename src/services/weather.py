import requests
import os
from typing import Dict, Optional
from datetime import datetime
from src.config.logging import setup_logging
from src.config.settings import settings
from src.database import get_db, WeatherData
from src.models.schemas import WeatherResponse
from sqlalchemy.orm import Session
import logging

logger = setup_logging()

class WeatherService:
    def __init__(self):
        self.api_key = settings.weather_api_key
        self.base_url = os.getenv("WEATHER_API_URL", "https://api.openweathermap.org/data/2.5")
        self.default_city = os.getenv("DEFAULT_CITY", "London")
        self.default_country = os.getenv("DEFAULT_COUNTRY", "UK")
        
        if not self.api_key or self.api_key == "your_openweathermap_api_key_here":
            logger.warning("Weather API key not found, running in test mode")
    
    def get_current_weather(self, city: str = None, country: str = None, db: Session = None) -> Dict:
        """Get current weather for a city and store it in database."""
        city = city or self.default_city
        country = country or self.default_country
        
        logger.info(f"Fetching weather data for {city}, {country}")
        
        if not self.api_key or self.api_key == "your_openweathermap_api_key_here":
            weather_data = self._get_test_weather(city, country)
        else:
            weather_data = self._fetch_weather_from_api(city, country)
        
        # Store in database if available
        if db and weather_data["status"] == "success":
            self._store_weather_data(db, weather_data["data"])
        
        return weather_data
    
    def _fetch_weather_from_api(self, city: str, country: str) -> Dict:
        """Fetch weather data from OpenWeatherMap API."""
        try:
            url = f"{self.base_url}/weather"
            params = {
                "q": f"{city},{country}",
                "appid": self.api_key,
                "units": "metric"
            }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            weather_data = {
                "city": data["name"],
                "temperature": data["main"]["temp"],
                "description": data["weather"][0]["description"],
                "humidity": data["main"]["humidity"],
                "feels_like": data["main"]["feels_like"],
                "timestamp": datetime.fromtimestamp(data["dt"])
            }
            
            logger.info(f"Weather data fetched successfully for {weather_data['city']}, temperature: {weather_data['temperature']}°C")
            
            return {
                "status": "success",
                "data": weather_data
            }
            
        except Exception as e:
            logger.error(f"Failed to fetch weather data for {city}: {str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }
    
    def _get_test_weather(self, city: str, country: str) -> Dict:
        """Return test weather data when API key is not available."""
        logger.info(f"Using test weather data for {city}, {country}")
        
        return {
            "status": "success",
            "data": {
                "city": city,
                "temperature": 22.5,
                "description": "partly cloudy",
                "humidity": 65,
                "feels_like": 24.0,
                "timestamp": datetime.now()
            }
        }
    
    def _store_weather_data(self, db: Session, weather_data: Dict):
        """Store weather data in the database."""
        try:
            db_weather = WeatherData(
                city=weather_data["city"],
                temperature=weather_data["temperature"],
                description=weather_data["description"],
                humidity=weather_data.get("humidity"),
                feels_like=weather_data.get("feels_like")
            )
            
            db.add(db_weather)
            db.commit()
            
            logger.info(f"Weather data stored in database for {weather_data['city']}, record ID: {db_weather.id}")
            
        except Exception as e:
            logger.error(f"Failed to store weather data for {weather_data['city']}: {str(e)}")
            db.rollback()
    
    def format_weather_message(self, weather_data: Dict) -> str:
        """Format weather data into a readable message."""
        if weather_data["status"] != "success":
            return f"Weather Error: {weather_data.get('error', 'Unknown error')}"
        
        data = weather_data["data"]
        
        message = f"""Weather Update for {data['city']}

Temperature: {data['temperature']}°C
Conditions: {data['description'].title()}"""
        
        if data.get('feels_like'):
            message += f"\nFeels like: {data['feels_like']}°C"
        
        if data.get('humidity'):
            message += f"\nHumidity: {data['humidity']}%"
        
        message += f"\n\nLast updated: {data['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}"
        
        return message