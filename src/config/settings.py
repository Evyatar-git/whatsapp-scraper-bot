import os
from typing import Optional

class Settings:
    def __init__(self):
        self.database_url = os.getenv("DATABASE_URL", "sqlite:///./weather_bot.db")
        self.api_host = os.getenv("API_HOST", "0.0.0.0")
        self.api_port = int(os.getenv("API_PORT", "8000"))
        self.debug = os.getenv("DEBUG", "false").lower() == "true"
        self.log_level = os.getenv("LOG_LEVEL", "INFO")
        self.weather_api_key = os.getenv("WEATHER_API_KEY", "")
        
    def validate(self):
        if not self.weather_api_key:
            raise ValueError("WEATHER_API_KEY environment variable is required")
        return True

settings = Settings()
