# --------------------------------------------
# ✅ Task-11: Blue/Green Deployment with CodeDeploy
# --------------------------------------------

provider "aws" {
  region = var.region
}

# IAM Role (Data source)
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# VPC, Subnets, IGW, Route Tables
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

# --------------------------------------------
# ✅ Security Groups
# --------------------------------------------

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------------------
# ✅ ECS Cluster
# --------------------------------------------

resource "aws_ecs_cluster" "strapi_cluster1" {
  name = "strapi-cluster1"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --------------------------------------------
# ✅ Load Balancer + Target Groups
# --------------------------------------------

resource "aws_lb" "strapi_alb" {
  name               = "strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "blue_tg" {
  name        = "strapi-blue-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "green_tg" {
  name        = "strapi-green-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_tg.arn
  }
}

# --------------------------------------------
# ✅ ECS Task Definition
# --------------------------------------------

resource "aws_ecs_task_definition" "strapi_task1" {
  family                   = "strapi-task1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "strapi"
    image     = var.image_url
    essential = true
    portMappings = [{
      containerPort = var.app_port
      protocol      = "tcp"
    }]
    environment = [
      { name = "NODE_ENV", value = "development" },
      { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
      { name = "APP_KEYS", value = var.app_keys },
      { name = "API_TOKEN_SALT", value = var.api_token_salt },
      { name = "TRANSFER_TOKEN_SALT", value = var.transfer_token_salt },
      { name = "ENCRYPTION_KEY", value = var.encryption_key }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/strapi"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# --------------------------------------------
# ✅ ECS Service for CodeDeploy
# --------------------------------------------

resource "aws_ecs_service" "strapi_service1" {
  name            = "strapi-service1"
  cluster         = aws_ecs_cluster.strapi_cluster1.id
  task_definition = aws_ecs_task_definition.strapi_task1.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue_tg.arn
    container_name   = "strapi"
    container_port   = var.app_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# --------------------------------------------
# ✅ CodeDeploy Application & Deployment Group
# --------------------------------------------

resource "aws_codedeploy_app" "strapi_app" {
  name              = "strapi-cd-app"
  compute_platform  = "ECS"
}

resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-strapi-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

resource "aws_iam_role_policy" "codedeploy_inline" {
  name = "codedeploy-ecs-access"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeTaskDefinition",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_codedeploy_deployment_group" "strapi_dg" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "strapi-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce" # ✅ Fix for ECS platform

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster1.name
    service_name = aws_ecs_service.strapi_service1.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.blue_tg.name
      }
      target_group {
        name = aws_lb_target_group.green_tg.name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http_listener.arn]
      }
    }
  }
}
#finish