variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "image_url" {
  description = "URL of Docker image in ECR"
  type        = string
  default     = "057569470997.dkr.ecr.ap-south-1.amazonaws.com/mansibite:latest"
}

variable "app_port" {
  description = "Port Strapi app listens on"
  type        = number
  default     = 1337
}

variable "app_keys" {
  description = "App keys for Strapi middleware"
  type        = string
}

variable "admin_jwt_secret" {
  description = "Secret for Strapi Admin JWT"
  type        = string
}

variable "api_token_salt" {
  description = "Salt for API token"
  type        = string
}

variable "transfer_token_salt" {
  description = "Salt for Transfer token"
  type        = string
}

variable "encryption_key" {
  description = "Encryption key for Strapi"
  type        = string
}

variable "flag_nps" {
  description = "Enable or disable NPS feature"
  type        = bool
  default     = true
}

variable "flag_promote_ee" {
  description = "Enable or disable Promote EE feature"
  type        = bool
  default     = true
}
