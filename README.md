# WhatsApp Web Scraper Bot

A production-ready WhatsApp bot that automatically scrapes websites and returns formatted content via WhatsApp messaging. Deployed on AWS with enterprise-grade infrastructure using Infrastructure as Code.

## Features

- **Real-time WhatsApp Integration**: Processes messages via Twilio WhatsApp API
- **Automatic Web Scraping**: Detects URLs and extracts content automatically
- **Interactive Commands**: Support for help, ping, and URL processing
- **Smart Content Extraction**: Titles, content previews, and metadata
- **AWS Production Infrastructure**: Scalable, secure cloud deployment
- **Infrastructure as Code**: Complete Terraform configuration with modules
- **Cost Optimization**: Automated deployment and destruction for portfolio use

## Architecture

### Application Stack
- **FastAPI**: Web server with webhook handling
- **Twilio WhatsApp API**: Message sending/receiving
- **BeautifulSoup4**: Web content scraping and parsing
- **Docker**: Containerized deployment

### AWS Infrastructure
- **ECS Fargate**: Serverless container hosting
- **Application Load Balancer**: Public HTTPS endpoint
- **ECR**: Container image registry
- **Parameter Store**: Secure credential management
- **CloudWatch**: Logging and monitoring
- **VPC**: Isolated network environment

## Prerequisites

- AWS Account with configured CLI
- Terraform >= 1.0
- Docker Desktop
- Twilio account with WhatsApp API access
- Git

## Quick Start

### Infrastructure Deployment

```bash
# Clone repository
git clone <repository-url>
cd whatsapp-scraper-bot

# Deploy AWS infrastructure
scripts/deploy-demo.bat

# Note the load balancer URL from outputs
```

### Application Configuration

Store Twilio credentials securely in AWS Parameter Store:
```bash
aws ssm put-parameter --name "whatsapp-scraper-account-sid" --value "ACxxxxx" --type "SecureString"
aws ssm put-parameter --name "whatsapp-scraper-auth-token" --value "xxxxx" --type "SecureString"
aws ssm put-parameter --name "whatsapp-scraper-whatsapp-from" --value "whatsapp:+14155238886" --type "String"
```

### Twilio Webhook Setup
Configure your Twilio WhatsApp webhook to point to:
```
http://your-load-balancer-dns.elb.amazonaws.com/webhook
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

## Project Structure

```
├── src/
│   ├── api/main.py           # FastAPI application & webhook handler
│   └── workers/scraper.py    # Web scraping engine
├── scripts/
│   ├── deploy-demo.bat       # Deploy infrastructure for demonstrations
│   ├── cleanup-demo.bat      # Destroy infrastructure to stop costs
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
├── run.py                    # Application launcher
├── requirements.txt          # Python dependencies
├── Dockerfile               # Container configuration
├── docker-compose.yml       # Local development setup
└── .env.example             # Environment variable template
```

## API Endpoints

- `GET /` - Health check
- `GET /health` - Service status with Twilio configuration
- `POST /webhook` - WhatsApp message handler
- `POST /test-scrape` - Direct scraping API (form data)
- `GET /test-scrape` - Direct scraping API (query parameter)

## Cost Management

This project demonstrates cost-conscious DevOps practices suitable for portfolio use.

### Cost Structure
- **Application Load Balancer**: $16.20/month (main cost driver)
- **ECS Fargate**: Free tier (20 GB-hours/month)
- **ECR Storage**: Free tier (500 MB)
- **Parameter Store**: Free (standard parameters)
- **CloudWatch Logs**: Free tier (5 GB/month)

**Total when running**: ~$16.20/month  
**Total when stopped**: $0/month

### Demo Commands
```bash
# Deploy for demonstration/interviews
scripts/deploy-demo.bat

# Check current costs
scripts/cost-status.bat

# Destroy to stop AWS charges
scripts/cleanup-demo.bat
```
y
## Local Development

```bash
# For local development and testing
cp .env.example .env.local
# Edit .env.local with credentials

pip install -r requirements.txt  # Install dependencies
python run.py                    # Start development server
docker-compose up -d             # Run with Docker Compose
```

## Infrastructure Management

```bash
# Terraform commands (from terraform/environments/dev)
terraform init     # Initialize Terraform
terraform plan     # Plan infrastructure changes
terraform apply    # Apply infrastructure changes
terraform destroy  # Destroy infrastructure
```

## Production Features

### Security
- **IAM Roles**: Least privilege access for ECS tasks
- **Parameter Store**: Encrypted credential storage
- **VPC**: Network isolation with security groups
- **Container Scanning**: ECR vulnerability scanning

### Scalability
- **Auto Scaling**: ECS Fargate handles traffic spikes automatically
- **Load Balancer**: Distributes traffic across containers
- **Multi-AZ**: High availability across availability zones
- **Container Registry**: Versioned image deployments

### Monitoring
- **CloudWatch Logs**: Centralized application logging
- **Health Checks**: Load balancer monitors container health
- **Container Insights**: ECS performance metrics
- **Cost Monitoring**: Automated resource tracking

## Environment Management

The infrastructure supports multiple environments with isolated resources:
- **Development**: `terraform/environments/dev/`
- **Staging**: `terraform/environments/staging/`
- **Production**: `terraform/environments/prod/`

Each environment has separate VPC, ECS clusters, load balancers, and Parameter Store namespaces.

## Technology Stack

- **Backend**: FastAPI (Python 3.11)
- **Messaging**: Twilio WhatsApp Cloud API  
- **Scraping**: BeautifulSoup4, Requests, lxml
- **Infrastructure**: AWS (ECS, ALB, ECR, Parameter Store, VPC)
- **IaC**: Terraform with modular architecture
- **Containerization**: Docker with ECS Fargate
- **Config**: AWS Parameter Store + Environment variables


## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test changes locally with docker-compose
4. Update Terraform configurations if infrastructure changes needed
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## DevOps Practices Demonstrated

This project showcases enterprise-level DevOps capabilities:
- Infrastructure as Code with modular Terraform
- Containerized microservices on AWS
- Secure credential management and secrets handling
- Production-ready monitoring and logging
- Cost optimization and resource lifecycle management
- Multi-environment deployment strategies
- Automated infrastructure provisioning and destruction
