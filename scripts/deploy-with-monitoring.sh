#!/bin/bash

# Deploy Weather Bot with Optional Monitoring
# This script allows you to deploy with or without monitoring based on cost preferences

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Weather Bot Deployment with Cost Options${NC}"
echo ""

# Cost Analysis
echo -e "${YELLOW}Cost Analysis:${NC}"
echo "Current monthly costs (estimated):"
echo "• Application only: ~$24/month"
echo "• With monitoring:  ~$37/month (adds ~$13/month)"
echo ""
echo "Monitoring adds:"
echo "• Prometheus: 0.25 vCPU, 512MB RAM"
echo "• Grafana: 0.25 vCPU, 512MB RAM" 
echo "• Additional CloudWatch logs"
echo ""

# Ask user preference
read -p "Enable monitoring stack? (y/N): " enable_monitoring

if [[ $enable_monitoring =~ ^[Yy]$ ]]; then
    MONITORING_FLAG="-var enable_monitoring=true"
    echo -e "${GREEN}Monitoring enabled - deploying Prometheus + Grafana${NC}"
    ESTIMATED_COST="~$37/month"
else
    MONITORING_FLAG="-var enable_monitoring=false"
    echo -e "${YELLOW}Monitoring disabled - cost optimized deployment${NC}"
    ESTIMATED_COST="~$24/month"
fi

echo ""
echo -e "${BLUE}Deployment Summary:${NC}"
echo "• Monitoring: $([ "$enable_monitoring" = "y" ] && echo "Enabled" || echo "Disabled")"
echo "• Estimated cost: $ESTIMATED_COST"
echo "• Log retention: 7 days (cost optimized)"
echo "• Resources: Minimal Fargate tasks"
echo ""

read -p "Proceed with deployment? (y/N): " proceed
if [[ ! $proceed =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo -e "${BLUE}Deploying infrastructure...${NC}"

cd terraform/environments/dev

# Deploy with monitoring option
terraform init
terraform plan $MONITORING_FLAG
terraform apply $MONITORING_FLAG -auto-approve

# Get outputs
ALB_DNS=$(terraform output -raw load_balancer_dns)

echo ""
echo -e "${GREEN}Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}Access Information:${NC}"
echo "• Application: http://$ALB_DNS"
echo "• Health Check: http://$ALB_DNS/health"
echo "• Metrics: http://$ALB_DNS/metrics"

if [[ $enable_monitoring =~ ^[Yy]$ ]]; then
    echo "• Prometheus: http://$ALB_DNS/prometheus"
    echo "• Grafana: http://$ALB_DNS/grafana (admin/admin)"
fi

echo ""
echo -e "${YELLOW}Cost Management:${NC}"
echo "• Estimated monthly cost: $ESTIMATED_COST"
echo "• Run 'terraform destroy' when done to avoid charges"
echo "• Monitor costs in AWS Cost Explorer"

cd ../../..
