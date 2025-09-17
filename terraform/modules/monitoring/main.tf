# Monitoring Module - Prometheus + Grafana on ECS
# This deploys monitoring alongside your application automatically

resource "aws_ecs_service" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  
  name            = "${var.name}-prometheus"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.prometheus[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.monitoring[0].id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus[0].arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  depends_on = [aws_lb_listener_rule.prometheus[0]]

  tags = var.tags
}

resource "aws_ecs_service" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  
  name            = "${var.name}-grafana"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.monitoring[0].id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana[0].arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener_rule.grafana[0]]

  tags = var.tags
}

# Task Definitions
resource "aws_ecs_task_definition" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  
  family                   = "${var.name}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"  # Minimal resources
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "prometheus"
      image = "prom/prometheus:latest"
      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]
      command = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--web.console.libraries=/etc/prometheus/console_libraries",
        "--web.console.templates=/etc/prometheus/consoles",
        "--storage.tsdb.retention.time=7d",  # Cost optimization
        "--web.enable-lifecycle"
      ]
      environment = [
        {
          name  = "TZ"
          value = "UTC"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.monitoring[0].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "prometheus"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_task_definition" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  
  family                   = "${var.name}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"  # Minimal resources
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "grafana/grafana:latest"
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = "admin"
        },
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "admin"
        },
        {
          name  = "GF_USERS_ALLOW_SIGN_UP"
          value = "false"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.monitoring[0].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "grafana"
        }
      }
    }
  ])

  tags = var.tags
}

# Load Balancer Integration
resource "aws_lb_target_group" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  
  name        = "${var.name}-prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/-/healthy"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.name}-prometheus-tg"
  })
}

resource "aws_lb_target_group" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  
  name        = "${var.name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.name}-grafana-tg"
  })
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  
  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus[0].arn
  }

  condition {
    path_pattern {
      values = ["/prometheus*"]
    }
  }
}

resource "aws_lb_listener_rule" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  
  listener_arn = var.alb_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana[0].arn
  }

  condition {
    path_pattern {
      values = ["/grafana*"]
    }
  }
}

# Security Group
resource "aws_security_group" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  name_prefix = "${var.name}-monitoring-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-monitoring-sg"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  name              = "/ecs/${var.name}-monitoring"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

data "aws_region" "current" {}
