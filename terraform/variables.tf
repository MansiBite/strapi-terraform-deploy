# AWS Region
variable "region" {
  default = "ap-south-1"
}

# Docker Image URL (from ECR)
variable "image_url" {
  default = "057569470997.dkr.ecr.ap-south-1.amazonaws.com/mansibite:latest"
}

# Application Port (Strapi default)
variable "app_port" {
  default = 1337
}

# CPU and Memory for ECS Fargate Task
variable "task_cpu" {
  description = "CPU units for ECS task (e.g., 1024 = 1 vCPU)"
  default     = "1024"
}

variable "task_memory" {
  description = "Memory (in MiB) for ECS task (e.g., 3072 = 3GB)"
  default     = "3072"
}

# Strapi secret environment variables from GitHub Actions
variable "app_keys" {
  description = "Strapi APP_KEYS"
  type        = string
}

variable "admin_jwt_secret" {
  description = "Strapi ADMIN_JWT_SECRET"
  type        = string
}

variable "api_token_salt" {
  description = "Strapi API_TOKEN_SALT"
  type        = string
}

variable "transfer_token_salt" {
  description = "Strapi TRANSFER_TOKEN_SALT"
  type        = string
}

variable "encryption_key" {
  description = "Strapi ENCRYPTION_KEY"
  type        = string
}
