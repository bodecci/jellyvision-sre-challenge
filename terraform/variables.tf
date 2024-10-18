# AWS Configuration
variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type        = string
  default     = "bode_profile"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "933071741192"
}

# ECS Configuration
variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
  default     = "simpsons-cluster"
}

variable "ecs_task_family" {
  description = "ECS Task Definition Family"
  type        = string
  default     = "simpsons-simulator-task"
}

variable "ecs_service_name" {
  description = "ECS Service Name"
  type        = string
  default     = "simpsons-simulator-service"
}

variable "container_name" {
  description = "Container Name"
  type        = string
  default     = "simpsons-container"
}

variable "image_tag" {
  description = "Docker image tag for ECR"
  type        = string
  default     = "1.3"
}

# ACM Certificate for HTTPS
# variable "certificate_arn" {
#  description = "ARN of the ACM Certificate for the domain"
#  type        = string
#  default     = "arn:aws:acm:us-east-1:933071741192:certificate/abcd1234-56ef-78gh-90ij-klmnopqrstuv"
# }

# Network Configuration
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Security Groups
variable "alb_sg_description" {
  description = "Description of the security group for the ALB"
  type        = string
  default     = "Security group for the Application Load Balancer (ALB)"
}

variable "ecs_sg_description" {
  description = "Description of the security group for ECS tasks"
  type        = string
  default     = "Security group for ECS tasks in the private subnets"
}
