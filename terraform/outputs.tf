output "strapi_url" {
  description = "Access your Strapi app using the ALB"
  value       = aws_lb.strapi_alb.dns_name
}
