from src.services.weather import WeatherService
from src.database import get_db, init_database

# Initialize database
init_database()

# Test weather service
ws = WeatherService()
db = next(get_db())

result = ws.get_current_weather('London', db=db)
print('Status:', result['status'])
print('City:', result['data']['city'])
print('Temperature:', result['data']['temperature'], '°C')

db.close()
