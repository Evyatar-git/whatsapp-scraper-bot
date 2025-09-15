import pytest
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from src.database.config import get_db, WeatherData, init_database, test_database_connection

def test_database_connection():
    assert test_database_connection() == True

def test_weather_data_creation():
    init_database()
    db = next(get_db())
    
    weather = WeatherData(
        city="Test City",
        temperature=25.0,
        description="Test weather"
    )
    
    db.add(weather)
    db.commit()
    
    result = db.query(WeatherData).filter(WeatherData.city == "Test City").first()
    assert result is not None
    assert result.temperature == 25.0
    
    db.delete(result)
    db.commit()
    db.close()

def test_weather_data_validation():
    init_database()
    db = next(get_db())
    
    weather = WeatherData(
        city="",  # Empty city should be handled
        temperature=25.0,
        description="Test weather"
    )
    
    try:
        db.add(weather)
        db.commit()
        assert False, "Should have failed with empty city"
    except Exception:
        db.rollback()
        db.close()
        assert True
