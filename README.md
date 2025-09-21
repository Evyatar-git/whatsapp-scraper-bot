# Weather Bot (WhatsApp)  
![CI](https://github.com/Evyatar-git/whatsapp-weather-bot/actions/workflows/ci.yml/badge.svg)

A production-ready WhatsApp Weather Bot built with FastAPI featuring enterprise-grade DevOps practices. Includes real-time monitoring, automated security scanning, Infrastructure as Code, and complete AWS deployment pipeline.

## What it does
- Accepts a city name over WhatsApp and replies with: city, temperature, description, humidity, feels_like, created_at
- Stores weather lookups in SQLite for persistence
- Supports offline mode when no OpenWeather API key is provided

## Tech Stack
- **FastAPI** (Python 3.11) with Prometheus metrics
- **Twilio WhatsApp API** for messaging
- **SQLite + SQLAlchemy 2.0** for persistence
- **Pydantic** models with validation
- **Docker** multi-stage builds with security hardening
- **Terraform** (custom AWS modules for VPC, EKS, ALB)
- **Kubernetes (EKS)** with Helm charts for deployment
- **Prometheus + Grafana** for monitoring and observability
- **Automated security scanning** (Trivy, Bandit, Safety)
- **Pre-commit hooks** for code quality and security

## DevOps Features
- **Security**: Automated vulnerability scanning, pre-commit hooks, container hardening
- **Monitoring**: Prometheus metrics, Grafana dashboards, custom business metrics
- **Infrastructure**: Terraform modules for AWS (VPC, EKS, ALB, ECR)
- **Kubernetes**: EKS cluster with Helm charts, auto-scaling, health checks
- **CI/CD**: GitHub Actions with security gates and automated testing
- **Containers**: Multi-stage builds, non-root users, health checks
- **Cost Management**: Minimal resources, destroy/rebuild capability

## Prerequisites
- Docker Desktop
- Python 3.11 (optional for local dev without containers)
- Twilio account with WhatsApp Sandbox (for messaging)
- OpenWeatherMap API key (optional; enables live mode)
- AWS CLI configured (for production deployment)
- Terraform (for infrastructure deployment)
- kubectl (for Kubernetes cluster management)
- Helm (for application deployment)

## Configuration
Environment variables (via Docker Compose or AWS Parameter Store):
- `WEATHER_API_KEY` (required for live weather data; otherwise offline mode)
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM` (for outbound messages)
- `API_HOST` (default `0.0.0.0`), `API_PORT` (default `8000`), `LOG_LEVEL` (default `INFO`)

AWS Parameter Store is used for secure credential management in production. Do not commit real secrets.

## Run locally (Docker Compose)
```bash
docker-compose up --build
# API at http://localhost:8000

# Test weather endpoint (offline mode if no API key)
curl -X POST http://localhost:8000/weather -H "Content-Type: application/json" -d '{"city":"London"}'
```

Notes:
- The compose file sets `API_HOST=0.0.0.0` and `API_PORT=8000` by default.
- Healthcheck is enabled; container will report healthy when `/health` returns 200.
- Optional local conveniences (commented in `docker-compose.yml`):
  - Map `./.env.local` to `/app/.env` if you use a local env file
  - Mount `./src` for hot-reload during development


## Twilio WhatsApp setup
1) Enable WhatsApp in Twilio Console
2) Configure WhatsApp messaging service
3) Set the webhook URL to your bot endpoint (local: use `ngrok http 8000` and configure the public URL)
4) Environment vars required: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`

Local webhook test:
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


## Security and secrets
- Do not commit real secrets. Use AWS Parameter Store for production
- Terraform references SSM Parameter Store ARNs (see `terraform/environments/dev/main.tf`)
- `.gitignore` excludes `.env*`, `*.db`, `*.log`, security reports

## Cost efficiency
- Local-first development with Docker Compose
- Offline mode avoids external API calls when no key is set
- Terraform modules prepared for on-demand deployments (destroy when not in use)

## Development tips
- Logs write to console and `weather_bot.log`; adjust `LOG_LEVEL`
- SQLite file `weather_bot.db` is volume-mounted in Docker Compose
- Pydantic validates input (rejects empty or numeric city names)

## Quick Start
```bash
# 1. Clone and setup
git clone <repository-url>
cd whatsapp-weather-bot

# 2. Install pre-commit hooks (recommended)
make pre-commit-install

# 3. Run locally with monitoring
docker compose up --build

# 4. Access services
# - Application: http://localhost:8000
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
```

## Developer Workflow

### Development Commands
```bash
# Setup and quality
make pre-commit-install     # Install pre-commit hooks
make security-scan         # Run comprehensive security scan
make ci                    # Full check pipeline (lint + type + tests)

# Local development
docker compose up --build   # Start app with monitoring
make monitoring-up         # Start monitoring stack only
make logs                  # View application logs

# Testing
make test                  # Run pytest suite
curl -X POST http://localhost:8000/weather \
  -H "Content-Type: application/json" \
  -d '{"city":"London"}'   # Test weather API
```

### Production Deployment
```bash
# AWS deployment (requires AWS CLI configured)
make aws-setup-secrets     # Store credentials in Parameter Store
make aws-deploy-production # Deploy complete infrastructure
make aws-destroy          # Destroy infrastructure (stop billing)
```

### CI
- GitHub Actions runs on every push/PR:
  - Install deps, run tests, ruff lint, and mypy type checks
  - Failing checks block merges so the repo stays healthy

## Production deploy (AWS/EKS/ALB)
Automated deployment with Kubernetes and cost management:

### Quick Deploy:
```bash
# 1. Store secrets in AWS Parameter Store
make aws-setup-secrets

# 2. Deploy complete infrastructure + application to EKS
make aws-deploy-production

# 3. Configure Twilio webhook with provided ALB URL
# 4. Test WhatsApp integration
```

### Cost Management:
```bash
# Stop ALL billing immediately
make aws-destroy

# Check current costs
make aws-status
```

### Manual Steps:
1. Save secrets in AWS SSM Parameter Store:
   - `weather-bot-account-sid`, `weather-bot-auth-token`, `weather-bot-whatsapp-from`
   - `weather-bot-openweather-key`
2. In `terraform/environments/dev`:
   - `terraform init && terraform apply`
3. Build and push Docker image to ECR; deploy to EKS using Helm.
4. In Twilio Console, set webhook to `http://<ALB_DNS>/webhook`.
5. Test by sending a city in WhatsApp.

### Estimated Costs:
- **EKS cluster**: ~$72/month (control plane)
- **Worker nodes (2x t3.small SPOT)**: ~$15/month
- **ALB**: ~$16/month
- **Total**: ~$103/month
- **When destroyed**: $0/month

### EKS Management Commands:
```bash
# Connect kubectl to EKS cluster
make eks-connect

# Check cluster and application status
make eks-status

# View application logs
make eks-logs

# Scale application
kubectl scale deployment weather-bot -n weather-bot --replicas=3
```

Notes:
- Kubernetes pods read secrets from SSM via service accounts; redeploy to pick up changes.
- Logs are in CloudWatch `/aws/eks/weather-bot/cluster` and pod logs via kubectl.
- SQLite data is ephemeral in pods; use RDS if persistence is required.

## Project Architecture

```
├── src/                           # Application source code
│   ├── api/                      # FastAPI endpoints with Prometheus metrics
│   ├── config/                   # Settings and logging configuration
│   ├── database/                 # SQLAlchemy models and database setup
│   ├── models/                   # Pydantic request/response schemas
│   └── services/                 # Business logic (weather API integration)
├── terraform/                    # Infrastructure as Code
│   ├── modules/                  # Custom Terraform modules (VPC, EKS, ALB)
│   │   ├── vpc/                  # VPC with public/private subnets
│   │   ├── eks/                  # EKS cluster with node groups
│   │   └── alb-eks/              # ALB with AWS Load Balancer Controller
│   └── environments/dev/         # Environment-specific configurations
├── whatsapp-weather-bot-chart/   # Helm chart for Kubernetes deployment
│   ├── templates/                # Kubernetes resource templates
│   └── values.yaml               # Configuration values
├── monitoring/                   # Prometheus and Grafana configurations
├── scripts/                      # Deployment and utility scripts
├── tests/                        # Comprehensive test suite
└── .github/workflows/            # CI/CD pipeline with security scanning
```

## Security Features
- **Vulnerability Scanning**: Automated container and dependency scanning
- **Pre-commit Hooks**: Code quality and security checks before commits
- **Container Hardening**: Multi-stage builds, non-root users, minimal attack surface
- **Secrets Management**: AWS Parameter Store for production credentials
- **Network Security**: VPC isolation, security groups, ALB with health checks

## Monitoring & Observability
- **Custom Metrics**: Weather requests by city, WhatsApp message types, database operations
- **Grafana Dashboards**: Real-time visualization of application and business metrics
- **Health Checks**: Application and infrastructure health monitoring
- **Structured Logging**: JSON logs with correlation IDs and context