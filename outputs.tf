output "api_url" {
  description = "API endpoint."
  value       = module.api.url
}

output "environment" {
  description = "Environment label and Terraform workspace."
  value = {
    environment = var.environment
    workspace   = terraform.workspace
  }
}

output "containers" {
  description = "Container names."
  value = {
    api   = module.api.container_name
    redis = module.redis.hostname
  }
}

output "networks" {
  description = "Network names."
  value = {
    frontend = docker_network.frontend.name
    backend  = docker_network.backend.name
  }
}

output "redis_volume" {
  description = "Redis data volume (deleted by terraform destroy)."
  value       = module.redis.volume_name
}

output "redis_internal_address" {
  description = "Redis address on the private network (not published)."
  value       = module.redis.address
}

output "api_image_id" {
  description = "ID of the API image in use."
  value       = data.docker_image.api.id
}
