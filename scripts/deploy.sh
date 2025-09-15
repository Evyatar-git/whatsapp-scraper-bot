#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy.sh
# Requires: aws cli, docker, terraform

REGION=${REGION:-us-east-1}
export AWS_REGION="$REGION"

echo "[1/4] Terraform apply (VPC/ALB/ECS)"
pushd terraform/environments/dev > /dev/null
terraform init -input=false
terraform apply -auto-approve -input=false
ALB_URL=$(terraform output -raw load_balancer_url)
popd > /dev/null

echo "[2/4] ECR login"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "[3/4] Build and push image"
docker build -t weather-bot:latest .
docker tag weather-bot:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/weather-bot:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/weather-bot:latest"

echo "[4/4] Force ECS deploy"
aws ecs update-service --cluster weather-bot --service weather-bot --force-new-deployment >/dev/null

echo "Deployed. ALB URL: $ALB_URL"
echo "Set Twilio webhook to: ${ALB_URL%/}/webhook"

