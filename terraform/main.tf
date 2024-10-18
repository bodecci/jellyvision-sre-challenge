# Import DNS for jv_magic
data "aws_route53_zone" "jv_magic_zone" {
  name = "jv-magic.com"
}

# Reference the existing ACM Certificate for *.jv-magic.com
data "aws_acm_certificate" "jv_magic_cert" {
  domain       = "*.jv-magic.com"
  statuses     = ["ISSUED"]
  most_recent  = true
}

# VPC
resource "aws_vpc" "simpsons_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnets for ALB
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.simpsons_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.simpsons_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Private Subnets for ECS Tasks
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.simpsons_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.simpsons_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = "us-east-1b"
}

# Internet Gateway for the VPC
resource "aws_internet_gateway" "simpsons_igw" {
  vpc_id = aws_vpc.simpsons_vpc.id
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.simpsons_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.simpsons_igw.id
  }
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for ALB (allows inbound traffic on port 443 for HTTPS)
resource "aws_security_group" "alb_sg" {
  vpc_id      = aws_vpc.simpsons_vpc.id
  name_prefix = "alb-sg"
  description = var.alb_sg_description

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

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_sg" {
  vpc_id      = aws_vpc.simpsons_vpc.id
  name_prefix = "ecs-sg"
  description = var.ecs_sg_description

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "simpsons_alb" {
  name               = "simpsons-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

# Target Group for the ECS Service
resource "aws_lb_target_group" "simpsons_tg" {
  name         = "simpsons-target-group"
  port         = 4567
  protocol     = "HTTP"
  vpc_id       = aws_vpc.simpsons_vpc.id
  target_type  = "ip"
}

# ALB Listener for HTTPS
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.simpsons_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.jv_magic_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.simpsons_tg.arn
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the necessary ECS Task Execution Role policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "simpsons_cluster" {
  name = var.ecs_cluster_name
}

# ECS Task Definition
resource "aws_ecs_task_definition" "simpsons_task" {
  family                   = var.ecs_task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/simpsons_simulator:${var.image_tag}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 4567
          hostPort      = 4567
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = "/ecs/simpsons-simulator"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "simpsons_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.simpsons_cluster.id
  task_definition = aws_ecs_task_definition.simpsons_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.simpsons_tg.arn
    container_name   = var.container_name
    container_port   = 4567
  }

  depends_on = [aws_lb_listener.https_listener]
}
