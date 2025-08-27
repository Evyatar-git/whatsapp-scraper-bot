# WhatsApp Web Scraper Bot

A production-ready WhatsApp bot that automatically scrapes websites and returns formatted content via WhatsApp messaging.

## Features

- **Real-time WhatsApp Integration**: Processes messages via Twilio WhatsApp API
- **Automatic Web Scraping**: Detects URLs and extracts content automatically
- **Interactive Commands**: Support for help, ping, and URL processing
- **Smart Content Extraction**: Titles, content previews, and metadata
- **Production Ready**: Clean error handling, logging, and deployment setup

## Quick Start

### Prerequisites
- Python 3.11+
- Twilio account with WhatsApp API access
- ngrok for local webhook testing

### Installation
```bash
# Clone and setup
git clone <repository-url>
cd whatsapp-scraper-bot

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env.local
# Edit .env.local with your Twilio credentials
```

### Configuration
Update `.env.local` with your Twilio credentials:
```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

### Running
```bash
# Start the bot
python run.py

# In another terminal, expose webhook (for local development)
ngrok http 8000
# Configure Twilio webhook: https://your-ngrok-url.ngrok.io/webhook
```

## Usage

1. **Join Twilio WhatsApp Sandbox**: Send join code to Twilio number
2. **Send Commands**:
   - `hello` → Get welcome message
   - `help` → Show available commands  
   - `ping` → Test bot connectivity
   - **Any URL** → Automatically scrape and return content

### Example
Send: `https://example.com` → Receive formatted content with title, word count, and preview

## Architecture

- **FastAPI**: Web server with webhook handling
- **Twilio WhatsApp API**: Message sending/receiving
- **BeautifulSoup4**: Web content scraping and parsing
- **Docker**: Containerized deployment

## Development

### Project Structure
```
├── src/
│   ├── api/main.py           # FastAPI application & webhook handler
│   └── workers/scraper.py    # Web scraping engine
├── run.py                    # Application launcher
├── requirements.txt          # Python dependencies
├── Dockerfile               # Container configuration
├── docker-compose.yml       # Multi-service setup
└── Makefile                # Development commands
```

### API Endpoints
- `GET /` - Health check
- `GET /health` - Service status
- `POST /webhook` - WhatsApp message handler
- `POST /test-scrape` - Direct scraping API

### Development Commands
```bash
python run.py          # Start development server
make docker           # Run with Docker Compose
make ngrok            # Start ngrok tunnel
```

## Deployment

### Docker
```bash
# Build and run
docker build -t whatsapp-scraper-bot .
docker run -p 8000:8000 whatsapp-scraper-bot

# Or use docker-compose
docker-compose up -d
```

### Cloud Platforms
Ready for deployment to:
- **AWS** (ECS, Lambda, EC2)
- **Railway** / **Heroku**
- **Google Cloud Run**
- **DigitalOcean App Platform**

## Features & Status

- **Core Functionality**: Complete WhatsApp bot with scraping
- **Production Ready**: Error handling, clean code, documentation
- **Tested**: End-to-end functionality verified
- **Containerized**: Docker setup included
- **API Integration**: Real Twilio WhatsApp API
- **Web Scraping**: Robust content extraction

## Technology Stack

- **Backend**: FastAPI (Python 3.11)
- **Messaging**: Twilio WhatsApp Cloud API  
- **Scraping**: BeautifulSoup4, Requests, lxml
- **Infrastructure**: Docker, ngrok
- **Config**: Environment-based settings

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test locally with ngrok
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

**Professional DevOps Project** demonstrating:
- Real-time webhook processing
- Third-party API integration
- Web scraping and data processing  
- Production deployment practices
- Clean, maintainable architecture