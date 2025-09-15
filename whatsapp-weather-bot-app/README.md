# Weather Bot (WhatsApp)

A FastAPI-based WhatsApp Weather Bot that fetches current weather and replies via WhatsApp (Twilio). The project emphasizes DevOps best practices: containerization, Kubernetes, Helm, Terraform, structured logging, and secure configuration.

## What it does
- Accepts a city name over WhatsApp and replies with: city, temperature, description, humidity, feels_like, created_at
- Stores weather lookups in SQLite for demo/local use
- Runs in “test mode” when no real OpenWeather API key is provided

## Tech stack
- **FastAPI** (Python 3.11)
- **Twilio WhatsApp API** for messaging
- **SQLite + SQLAlchemy 2.0** for persistence
- **Pydantic** models for validation
- **Docker**, **Kubernetes** (Minikube locally), **Helm**, **Terraform** (AWS modules present but optional)
- **Logging** via Python logging configured to console and `weather_bot.log`

## Prerequisites
- Docker Desktop (optionally with Kubernetes/Minikube)
- kubectl, Helm (for K8s workflows)
- Python 3.11 (optional for local dev without containers)
- Twilio account with WhatsApp Sandbox (for messaging)
- OpenWeatherMap API key (optional; enables live mode)

## Configuration
Environment variables (via Docker, K8s Secret, or local shell):
- `WEATHER_API_KEY` (required for live mode; otherwise test mode)
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM` (for outbound messages)
- `API_HOST` (default `0.0.0.0`), `API_PORT` (default `8000`), `LOG_LEVEL` (default `INFO`)

Kubernetes Secret template is at `k8s/base/secret/app-secrets.yaml` with placeholders only. Do not commit real secrets.

## Run locally (Docker Compose)
```bash
docker-compose up --build
# API at http://localhost:8000

# Test weather endpoint (test mode if no API key)
curl -X POST http://localhost:8000/weather -H "Content-Type: application/json" -d '{"city":"London"}'
```

## Local Kubernetes (Minikube)
```bash
minikube start
eval $(minikube docker-env)
docker build -t weather-bot:latest .
kubectl apply -k k8s/base/
kubectl -n weather-bot get pods
kubectl -n weather-bot port-forward service/weather-bot-service 8000:80
# API at http://localhost:8000
```

## Twilio WhatsApp setup (Sandbox)
1) Enable WhatsApp Sandbox in Twilio Console
2) Join the sandbox by sending the provided code to `whatsapp:+14155238886`
3) Set the webhook URL to your bot endpoint (local: use `ngrok http 8000` and configure the public URL)
4) Environment vars required: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`

Example local webhook test (simulates Twilio):
```bash
curl -X POST http://localhost:8000/webhook \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "From=whatsapp:+1234567890&Body=London"
```

## API endpoints
- `GET /health` – health and DB connectivity check
- `POST /weather` – JSON body `{ "city": "London" }`
- `POST /webhook` – Twilio WhatsApp webhook (form-encoded)

## Project layout (high-level)
```
src/
  api/main.py           # FastAPI app, /health, /weather, /webhook
  config/settings.py    # Env-driven configuration
  config/logging.py     # Console + file logging
  database/config.py    # SQLAlchemy engine, models, init/health
  models/schemas.py     # Pydantic request/response models
  services/weather.py   # WeatherService (API or test mode)
k8s/base/               # Namespace, Deployment, Service, ConfigMap, Secret
whatsapp-weather-bot-chart/ # Helm chart (values updated for weather-bot)
terraform/              # AWS modules (VPC, ALB, ECS) for future use
```

## Security and secrets
- Do not commit real secrets. Placeholders only in K8s Secret and Helm values
- For AWS, reference SSM Parameter Store ARNs (see Terraform `environments/dev/main.tf`)
- `.gitignore` excludes `.env*`, `*.db`, `*.log`, caches

## Cost efficiency
- Local-first dev with Minikube and Docker Compose
- Test mode avoids external API calls when no key is set
- Terraform modules prepared for on-demand deployments (destroy when not in use)

## Development tips
- Logs write to console and `weather_bot.log`; adjust `LOG_LEVEL`
- SQLite file `weather_bot.db` is volume-mounted in Docker Compose
- Pydantic validates input (rejects empty or numeric city names)

## Roadmap
- Twilio send message helper and E2E WhatsApp flow
- EKS or ECS deployment with CI/CD
- Observability (structured logs/metrics)