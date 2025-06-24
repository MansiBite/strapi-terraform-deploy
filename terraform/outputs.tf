output "strapi_url" {
  description = "Access your Strapi app using this IP"
  value       = "http://${aws_ecs_service.strapi_service1.network_configuration[0].assign_public_ip ? "Check ECS console for Public IP" : "Only internal access"}"
}
