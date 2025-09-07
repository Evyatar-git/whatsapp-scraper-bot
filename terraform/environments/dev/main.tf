terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_count = var.public_subnet_count
  enable_nat_gateway  = var.enable_nat_gateway
  tags               = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name       = var.project_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    app = {
      port        = 8000
      protocol    = "HTTP"
      target_type = "ip"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }
  }

  listeners = {
    web = {
      port             = 80
      protocol         = "HTTP"
      target_group_key = "app"
    }
  }

  tags = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name                = var.project_name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn    = module.alb.target_group_arns["app"]
  
  container_port      = 8000
  desired_count       = var.desired_count
  cpu                 = var.container_cpu
  memory              = var.container_memory
  
  environment_variables = {
    DEBUG     = "false"
    API_HOST  = "0.0.0.0"
    API_PORT  = "8000"
  }

  secrets = {
    TWILIO_ACCOUNT_SID   = "arn:aws:ssm:us-east-1:719737572192:parameter/whatsapp-scraper-account-sid"
    TWILIO_AUTH_TOKEN    = "arn:aws:ssm:us-east-1:719737572192:parameter/whatsapp-scraper-auth-token"
    TWILIO_WHATSAPP_FROM = "arn:aws:ssm:us-east-1:719737572192:parameter/whatsapp-scraper-whatsapp-from"
  }

  tags = local.common_tags
}
