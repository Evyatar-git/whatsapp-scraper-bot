# WhatsApp Web Scraper Bot

A production-ready WhatsApp bot that automatically scrapes websites and returns formatted content via WhatsApp messaging. This project demonstrates comprehensive DevOps expertise across multiple container platforms and orchestration tools.

## Architecture Overview

This project implements the same application across four different deployment strategies:

### Application Stack
- **FastAPI**: Web server with webhook handling
- **Twilio WhatsApp API**: Message sending/receiving
- **BeautifulSoup4**: Web content scraping and parsing
- **Docker**: Containerized deployment

### Deployment Platforms

**1. AWS Production Infrastructure**
- **ECS Fargate**: Serverless container hosting
- **Application Load Balancer**: Public endpoint with health checks
- **ECR**: Container image registry
- **Parameter Store**: Secure credential management
- **CloudWatch**: Logging and monitoring
- **VPC**: Isolated network environment

**2. Kubernetes Container Orchestration**
- **Local Development**: Minikube cluster
- **Pod Management**: Deployments, ReplicaSets, Services
- **Configuration**: ConfigMaps and Secrets
- **Service Discovery**: ClusterIP and NodePort services
- **Health Monitoring**: Liveness and readiness probes

**3. Helm Package Management**
- **Templating**: Environment-specific configurations
- **Release Management**: Install, upgrade, rollback capabilities
- **Multi-Environment**: Dev and production value files
- **Package Distribution**: Chart-based deployment

**4. Local Development**
- **Docker Compose**: Multi-service local environment
- **Development Tools**: Hot reloading, debugging support

## Features

- **Real-time WhatsApp Integration**: Processes messages via Twilio WhatsApp API
- **Automatic Web Scraping**: Detects URLs and extracts content automatically
- **Interactive Commands**: Support for help, ping, and URL processing
- **Smart Content Extraction**: Titles, content previews, and metadata
- **Multi-Platform Deployment**: AWS, Kubernetes, Helm, Docker Compose
- **Infrastructure as Code**: Complete Terraform and Kubernetes manifests
- **Cost Optimization**: Automated deployment and destruction for portfolio use

## Prerequisites

- **AWS Account** with configured CLI
- **Terraform** >= 1.0
- **Docker Desktop** with Kubernetes enabled
- **kubectl** command-line tool
- **Helm** >= 3.0
- **Twilio account** with WhatsApp API access
- **Git**

## Quick Start

### AWS Production Deployment

```bash
# Clone repository
git clone <repository-url>
cd whatsapp-scraper-bot

# Deploy AWS infrastructure
scripts/deploy-demo.bat

# Configure Twilio webhook with load balancer URL
```

### Kubernetes Local Development

```bash
# Start minikube
minikube start

# Build image for minikube
eval $(minikube docker-env)
docker build -t whatsapp-scraper:latest .

# Deploy with kubectl
kubectl apply -k k8s/base/

# Or deploy with Helm
helm install whatsapp-scraper whatsapp-scraper-chart/
```

### Docker Compose Local Development

```bash
# Copy environment template
cp .env.example .env.local
# Edit .env.local with your Twilio credentials

# Start all services
docker-compose up -d
```

## Project Structure

```
├── src/
│   ├── api/main.py           # FastAPI application & webhook handler
│   └── workers/scraper.py    # Web scraping engine
├── scripts/
│   ├── deploy-demo.bat       # Deploy AWS infrastructure
│   ├── cleanup-demo.bat      # Destroy AWS infrastructure
│   └── cost-status.bat       # Check AWS resource costs
├── terraform/
│   ├── modules/              # Reusable infrastructure modules
│   │   ├── vpc/             # Networking components
│   │   ├── alb/             # Application Load Balancer
│   │   └── ecs/             # Container platform with ECR
│   └── environments/        # Environment-specific configurations
│       ├── dev/             # Development environment
│       ├── staging/         # Staging environment
│       └── prod/            # Production environment
├── k8s/
│   ├── base/                # Base Kubernetes manifests
│   │   ├── app/            # Deployment configuration
│   │   ├── configmap/      # Application configuration
│   │   ├── secret/         # Credential management
│   │   └── service/        # Service discovery
│   └── overlays/           # Environment-specific overlays
│       ├── local/          # Local development
│       ├── dev/            # Development cluster
│       └── prod/           # Production cluster
├── whatsapp-scraper-chart/ # Helm chart
│   ├── templates/          # Templated Kubernetes manifests
│   ├── values.yaml         # Default configuration values
│   └── Chart.yaml          # Chart metadata
├── values-dev.yaml         # Development Helm values
├── values-prod.yaml        # Production Helm values
├── docker-compose.yml      # Local development services
├── Dockerfile             # Container definition
└── requirements.txt       # Python dependencies
```

## Deployment Strategies

### AWS ECS Fargate (Production)

```bash
# Infrastructure deployment
scripts/deploy-demo.bat

# Application deployment (automatic via ECS)
# Configure Parameter Store secrets
aws ssm put-parameter --name "whatsapp-scraper-account-sid" --value "ACxxxxx" --type "SecureString"

# Access via load balancer URL
```

### Kubernetes with kubectl

```bash
# Deploy to cluster
kubectl apply -k k8s/base/

# Monitor deployment
kubectl get all -n whatsapp-scraper

# Access application
kubectl port-forward -n whatsapp-scraper deployment/whatsapp-scraper 8080:8000
```

### Helm Charts

```bash
# Install with default values
helm install whatsapp-scraper whatsapp-scraper-chart/

# Install production environment
helm install whatsapp-scraper-prod whatsapp-scraper-chart/ -f values-prod.yaml

# Upgrade deployment
helm upgrade whatsapp-scraper whatsapp-scraper-chart/
```

### Docker Compose

```bash
# Local development
docker-compose up -d

# View logs
docker-compose logs -f api

# Scale services
docker-compose up -d --scale api=2
```

## API Endpoints

- `GET /` - Health check
- `GET /health` - Service status with Twilio configuration
- `POST /webhook` - WhatsApp message handler
- `POST /test-scrape` - Direct scraping API (form data)
- `GET /test-scrape` - Direct scraping API (query parameter)

## Usage

1. **Join Twilio WhatsApp Sandbox**: Send join code to Twilio number
2. **Send Commands**:
   - `hello` → Get welcome message
   - `help` → Show available commands  
   - `ping` → Test bot connectivity
   - **Any URL** → Automatically scrape and return content

### Example
Send: `https://example.com` → Receive formatted content with title, word count, and preview

## Cost Management

### AWS Infrastructure Costs
- **Application Load Balancer**: $16.20/month (main cost driver)
- **ECS Fargate**: Free tier (20 GB-hours/month)
- **ECR Storage**: Free tier (500 MB)
- **Parameter Store**: Free (standard parameters)
- **CloudWatch Logs**: Free tier (5 GB/month)

**Total when running**: ~$16.20/month  
**Total when stopped**: $0/month

### Cost Optimization Commands
```bash
# Deploy for demonstrations
scripts/deploy-demo.bat

# Check current costs
scripts/cost-status.bat

# Destroy to stop charges
scripts/cleanup-demo.bat
```

## Technology Stack

**Application**: FastAPI (Python 3.11), BeautifulSoup4, Requests  
**Messaging**: Twilio WhatsApp Cloud API  
**Containerization**: Docker, Docker Compose  
**Orchestration**: Kubernetes, Helm  
**Cloud Infrastructure**: AWS (ECS, ALB, ECR, Parameter Store, VPC)  
**Infrastructure as Code**: Terraform with modular architecture  
**Configuration Management**: ConfigMaps, Secrets, Parameter Store  
**Monitoring**: CloudWatch, Kubernetes health checks  

## DevOps Practices Demonstrated

This project showcases the following DevOps capabilities:

**Infrastructure as Code**: Terraform modules for AWS, Kubernetes manifests  
**Container Orchestration**: ECS Fargate, Kubernetes deployments  
**Package Management**: Helm charts with templating  
**Multi-Environment Support**: Dev, staging, production configurations  
**Secure Credential Management**: AWS Parameter Store, Kubernetes Secrets  
**Cost Optimization**: Automated resource lifecycle management  
**Production Monitoring**: Health checks, logging, observability  
**Platform Portability**: Same application across multiple platforms  

## Environment Management

**Development**: Local Docker Compose, Minikube  
**Staging**: Kubernetes cluster, Helm deployments  
**Production**: AWS ECS Fargate, Terraform infrastructure  

Each environment uses appropriate configurations for security, scaling, and resource allocation.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test changes across multiple deployment platforms
4. Update infrastructure configurations as needed
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

**Comprehensive DevOps Portfolio Project** demonstrating multi-platform container orchestration, infrastructure automation, and production-ready deployment strategies across AWS and Kubernetes ecosystems.