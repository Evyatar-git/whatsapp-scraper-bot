#!/bin/bash

# Full AWS Production Deployment Script
# This script deploys the Weather Bot to AWS using Terraform + ECS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Weather Bot AWS Production Deployment${NC}"
echo "This will deploy your Weather Bot to AWS with full infrastructure"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI not found. Please install it first.${NC}"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform not found. Please install it first.${NC}"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker not found. Please install it first.${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo -e "${RED}AWS credentials not configured${NC}"
        echo "Please run: aws configure"
        exit 1
    fi
    
    echo -e "${GREEN}All prerequisites met${NC}"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${BLUE}🏗️ Deploying AWS infrastructure...${NC}"
    
    cd terraform/environments/dev
    
    # Initialize Terraform
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    terraform init
    
    # Plan deployment
    echo -e "${YELLOW}Planning deployment...${NC}"
    terraform plan
    
    # Ask for confirmation
    echo ""
    read -p "Do you want to proceed with infrastructure deployment? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo -e "${YELLOW}⏸️ Deployment cancelled${NC}"
        exit 0
    fi
    
    # Apply infrastructure
    echo -e "${YELLOW}Applying infrastructure...${NC}"
    terraform apply -auto-approve
    
    # Get outputs
    ALB_DNS=$(terraform output -raw alb_dns_name)
    ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
    
    echo -e "${GREEN}Infrastructure deployed successfully!${NC}"
    echo -e "${BLUE}ALB DNS: ${ALB_DNS}${NC}"
    echo -e "${BLUE}ECR Repository: ${ECR_REPOSITORY_URL}${NC}"
    
    # Save outputs for next steps
    echo "ALB_DNS=$ALB_DNS" > ../../../.aws-outputs
    echo "ECR_REPOSITORY_URL=$ECR_REPOSITORY_URL" >> ../../../.aws-outputs
    
    cd ../../..
}

# Build and push Docker image
build_and_push_image() {
    echo -e "${BLUE}🐳 Building and pushing Docker image...${NC}"
    
    # Source the outputs
    source .aws-outputs
    
    # Get AWS account ID and region
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    # Login to ECR
    echo -e "${YELLOW}Logging in to ECR...${NC}"
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Build image
    echo -e "${YELLOW}Building Docker image...${NC}"
    docker build -t weather-bot:latest .
    
    # Tag image for ECR
    docker tag weather-bot:latest $ECR_REPOSITORY_URL:latest
    docker tag weather-bot:latest $ECR_REPOSITORY_URL:$(date +%Y%m%d-%H%M%S)
    
    # Push to ECR
    echo -e "${YELLOW}Pushing to ECR...${NC}"
    docker push $ECR_REPOSITORY_URL:latest
    docker push $ECR_REPOSITORY_URL:$(date +%Y%m%d-%H%M%S)
    
    echo -e "${GREEN}Docker image pushed successfully!${NC}"
}

# Update ECS service
update_ecs_service() {
    echo -e "${BLUE}🔄 Updating ECS service...${NC}"
    
    # Force new deployment
    aws ecs update-service \
        --cluster weather-bot \
        --service weather-bot-service \
        --force-new-deployment
    
    echo -e "${GREEN}ECS service updated!${NC}"
    echo -e "${YELLOW}⏳ Waiting for deployment to complete...${NC}"
    
    # Wait for service to stabilize
    aws ecs wait services-stable \
        --cluster weather-bot \
        --services weather-bot-service
    
    echo -e "${GREEN}Deployment completed successfully!${NC}"
}

# Configure Twilio webhook
configure_webhook() {
    echo -e "${BLUE}📱 Webhook Configuration${NC}"
    
    source .aws-outputs
    
    echo ""
    echo -e "${YELLOW}🔧 Manual Step Required:${NC}"
    echo "1. Go to Twilio Console: https://console.twilio.com/"
    echo "2. Navigate to: Messaging → Try it out → Send a WhatsApp message"
    echo "3. In the 'Webhook URL' field, enter:"
    echo -e "${GREEN}   http://$ALB_DNS/webhook${NC}"
    echo "4. Save the configuration"
    echo ""
    echo -e "${BLUE}💡 Your application is now running at: http://$ALB_DNS${NC}"
}

# Main deployment flow
main() {
    check_prerequisites
    
    echo -e "${YELLOW}📋 Deployment Steps:${NC}"
    echo "1. Deploy AWS infrastructure (VPC, ALB, ECS, ECR)"
    echo "2. Build and push Docker image to ECR"  
    echo "3. Update ECS service with new image"
    echo "4. Configure Twilio webhook"
    echo ""
    
    read -p "Ready to start deployment? (y/N): " ready
    if [[ $ready != [yY] ]]; then
        echo -e "${YELLOW}⏸️ Deployment cancelled${NC}"
        exit 0
    fi
    
    deploy_infrastructure
    build_and_push_image
    update_ecs_service
    configure_webhook
    
    echo ""
    echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
    echo ""
    echo -e "${BLUE}📊 Your Weather Bot is now running in production:${NC}"
    echo -e "${GREEN}• Application URL: http://$(source .aws-outputs && echo $ALB_DNS)${NC}"
    echo -e "${GREEN}• Health Check: http://$(source .aws-outputs && echo $ALB_DNS)/health${NC}"
    echo -e "${GREEN}• Metrics: http://$(source .aws-outputs && echo $ALB_DNS)/metrics${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo "1. Configure Twilio webhook (see instructions above)"
    echo "2. Test WhatsApp integration by sending a city name"
    echo "3. Monitor logs in AWS CloudWatch"
    echo "4. Scale or destroy resources as needed"
    echo ""
    echo -e "${BLUE}💰 Cost Management:${NC}"
    echo "• Run 'terraform destroy' when done testing to avoid charges"
    echo "• Monitor costs in AWS Cost Explorer"
}

# Run main function
main "$@"
