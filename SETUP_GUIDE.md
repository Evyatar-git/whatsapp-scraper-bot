# Weather Bot Setup Guide

## Required API Keys

### 1. OpenWeatherMap API Key (Required for Real Weather Data)

1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Go to "My API Keys" section
4. Copy your API key
5. Create a `.env.local` file in the project root with:

```bash
# Weather API Configuration
WEATHER_API_KEY=your_actual_api_key_here
WEATHER_API_URL=https://api.openweathermap.org/data/2.5

# Other Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false
LOG_LEVEL=INFO
DATABASE_URL=sqlite:///./weather_bot.db
```

### 2. Twilio API Keys (Optional - for WhatsApp Integration)

1. Go to [Twilio Console](https://console.twilio.com/)
2. Get your Account SID and Auth Token
3. Add to `.env.local`:

```bash
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

## Running the Bot

### Without API Keys (Test Mode)
```bash
python run.py
```
- Uses test weather data
- No real weather API calls
- Perfect for testing

### With API Keys (Production Mode)
1. Create `.env.local` file with your API keys
2. Run: `python run.py`
3. Real weather data from OpenWeatherMap

## Testing the API

### Test Weather Endpoint
```bash
curl -X POST "http://localhost:8000/weather" \
     -H "Content-Type: application/json" \
     -d '{"city": "London"}'
```

### Test Health Endpoint
```bash
curl http://localhost:8000/health
```

## Deployment Options

1. **Local Development**: `python run.py`
2. **Docker**: `docker build -t weather-bot . && docker run -p 8000:8000 weather-bot`
3. **Kubernetes**: Use the provided Helm charts
4. **Cloud**: Deploy using Terraform configurations
