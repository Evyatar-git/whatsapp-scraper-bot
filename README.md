# Weather Bot (WhatsApp)  
![CI](https://github.com/Evyatar-git/whatsapp-weather-bot/actions/workflows/ci.yml/badge.svg)

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
- **Logging** to console (CloudWatch in AWS)

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

Notes:
- The compose file sets `API_HOST=0.0.0.0` and `API_PORT=8000` by default.
- Healthcheck is enabled; container will report healthy when `/health` returns 200.
- Optional local conveniences (commented in `docker-compose.yml`):
  - Map `./.env.local` to `/app/.env` if you use a local env file
  - Mount `./src` for hot-reload during development

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

Webhook security:
- Bot validates Twilio signatures on `/webhook` when `TWILIO_AUTH_TOKEN` is set.
- Ensure the webhook URL exactly matches the URL configured in Twilio Console.

## API endpoints
- `GET /health` – health and DB connectivity check
- `POST /weather` – JSON body `{ "city": "London" }`
- `POST /webhook` – Twilio WhatsApp webhook (form-encoded)

## Project layout (high-level)
```
src/
  api/main.py           # FastAPI app, /health, /weather, /webhook
  config/settings.py    # Env-driven configuration
  config/logging.py     # Console logging only
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

## Developer workflow

### Make targets
```bash
# run tests
make test

# lint (ruff) and type-check (mypy)
make lint
make type

# format with ruff
make fmt

# run the full local check pipeline (lint + type + tests)
make ci

# stop the stack
make stop
```

### CI
- GitHub Actions runs on every push/PR:
  - Install deps, run tests, ruff lint, and mypy type checks
  - Failing checks block merges so the repo stays healthy

## Production deploy (AWS/ECS/ALB)
High-level steps:
1. Save secrets in AWS SSM Parameter Store:
   - `weather-bot-account-sid`, `weather-bot-auth-token`, `weather-bot-whatsapp-from`
   - `weather-bot-openweather-key`
2. In `terraform/environments/dev`:
   - `terraform init && terraform apply`
3. Build and push Docker image to ECR; force ECS service redeploy.
4. In Twilio Sandbox, set webhook to `http://<ALB_DNS>/webhook`.
5. Test by sending a city in WhatsApp.

Notes
- ECS tasks read secrets from SSM; redeploy to pick up changes.
- Logs are in CloudWatch `/ecs/weather-bot`.
- SQLite data is ephemeral in ECS; use RDS if persistence is required.

## Roadmap
- EKS or ECS deployment with CI/CD
- Observability (structured logs/metrics)