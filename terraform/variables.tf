variable "region" {
  default = "ap-south-1"
}

variable "image_url" {
  default = "057569470997.dkr.ecr.ap-south-1.amazonaws.com/mansibite:latest"
}

variable "app_port" {
  default = 1337
}

# Strapi required secrets (will come from GitHub Actions secrets)
variable "app_keys" {}
variable "admin_jwt_secret" {}
variable "api_token_salt" {}
variable "transfer_token_salt" {}
variable "jwt_secret" {}
