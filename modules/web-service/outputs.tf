output "container_name" {
  description = "Container name."
  value       = docker_container.service.name
}

output "container_id" {
  description = "Container ID."
  value       = docker_container.service.id
}

output "host_port" {
  description = "Published host port."
  value       = var.host_port
}

output "url" {
  description = "HTTP endpoint on the host."
  value       = "http://${var.host_ip == "0.0.0.0" ? "localhost" : var.host_ip}:${var.host_port}"
}
