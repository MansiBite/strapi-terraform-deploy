variable "region" {
  default = "ap-south-1"
}

variable "image_url" {
  default = "057569470997.dkr.ecr.ap-south-1.amazonaws.com/mansibite:latest"
}

variable "app_port" {
  default = 1337
}

variable "app_keys" {
  description = "App keys for Strapi middleware"
  type        = string
}

