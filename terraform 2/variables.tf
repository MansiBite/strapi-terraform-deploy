variable "region" {
  default = "ap-south-1"
}

variable "image_url" {
  description = "ECR Image URI"
  type        = string
}

variable "app_port" {
  default = 1337
}
