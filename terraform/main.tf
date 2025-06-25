
provider "aws" {
  region = var.region
}

# IAM Role (Data source)

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}


resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_security_group" "strapi_sg" {
  name   = "strapi-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_ecs_cluster" "strapi_cluster1" {
  name = "strapi-cluster1"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "strapi_task1" {
  family                   = "strapi-task1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  
  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.image_url
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "ADMIN_JWT_SECRET"
          value = var.admin_jwt_secret
        },
        {
          name  = "APP_KEYS"
          value = var.app_keys
        },
        {
          name  = "API_TOKEN_SALT"
          value = var.api_token_salt
        },
        {
          name  = "TRANSFER_TOKEN_SALT"
          value = var.transfer_token_salt
        },
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi_logs.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "strapi_service1" {
  name            = "strapi-service1"
  cluster         = aws_ecs_cluster.strapi_cluster1.id
  task_definition = aws_ecs_task_definition.strapi_task1.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.strapi_sg.id]

  }
}


resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggered when CPU > 70%"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster1.name
    ServiceName = aws_ecs_service.strapi_service1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "HighMemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggered when Memory > 80%"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster1.name
    ServiceName = aws_ecs_service.strapi_service1.name
  }
}



resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "StrapiDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster1.name, "ServiceName", aws_ecs_service.strapi_service1.name],
            ["ECS/ContainerInsights", "MemoryUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster1.name, "ServiceName", aws_ecs_service.strapi_service1.name]
          ],
          view = "timeSeries",
          stacked = false,
          region = var.region,
          title = "Strapi ECS CPU & Memory"
        }
      }
    ]
  })
}
