variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "weather-bot"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets for Kubernetes pods"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = false  # Disabled for cost savings
}

# Cost optimization variables
variable "container_cpu" {
  description = "Container CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256  # Minimal for cost savings
}

variable "container_memory" {
  description = "Container memory in MB"
  type        = number
  default     = 512  # Minimal for cost savings
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1    # Minimal for cost savings
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights (costs extra)"
  type        = bool
  default     = false  # Disabled for cost savings
}

variable "log_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 7      # Reduced for cost savings
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus + Grafana)"
  type        = bool
  default     = false  # Set to true to enable monitoring
}