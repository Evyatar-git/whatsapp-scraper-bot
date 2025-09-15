from pydantic import BaseModel, Field, validator
from datetime import datetime
from typing import Optional

class WeatherRequest(BaseModel):
    city: str = Field(..., min_length=1, max_length=100, description="City name")
    
    @validator('city')
    def validate_city(cls, v):
        if not v.strip():
            raise ValueError('City name cannot be empty')
        if any(char.isdigit() for char in v):
            raise ValueError('City name cannot contain numbers')
        return v.strip().title()

class WeatherResponse(BaseModel):
    city: str
    temperature: float
    description: str
    humidity: Optional[int]
    feels_like: Optional[float]
    created_at: datetime

class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    timestamp: datetime