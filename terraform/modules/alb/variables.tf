variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where ALB will be placed"
  type        = list(string)
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port        = number
    protocol    = string
    target_type = string
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      interval            = number
      matcher             = string
      path                = string
      port                = string
      protocol            = string
      timeout             = number
      unhealthy_threshold = number
    })
  }))
}

variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port             = number
    protocol         = string
    target_group_key = string
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
