output "alb_dns_name" {
  description = "URL pública de la aplicación"
  value       = "http://${module.app.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = module.ecr.repository_url
}
