#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/destroy.sh
# Removes AWS infra and secrets to avoid charges

REGION=${REGION:-us-east-1}
export AWS_REGION="$REGION"

echo "[1/3] Terraform destroy"
pushd terraform/environments/dev > /dev/null
terraform destroy -auto-approve -input=false || true
popd > /dev/null

echo "[2/3] Force delete ECR repository (if exists)"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr delete-repository --repository-name weather-bot --force >/dev/null 2>&1 || true

echo "[3/3] Delete SSM parameters"
aws ssm delete-parameters --names \
  weather-bot-account-sid \
  weather-bot-auth-token \
  weather-bot-whatsapp-from \
  weather-bot-openweather-key >/dev/null 2>&1 || true

echo "Destroyed all resources and secrets."

