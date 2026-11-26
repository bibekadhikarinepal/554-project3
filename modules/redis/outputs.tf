output "hostname" {
  description = "DNS name of Redis on the network (the container name)."
  value       = docker_container.redis.name
}

output "port" {
  description = "Redis port on the private network (not published)."
  value       = 6379
}

output "address" {
  description = "host:port for clients on the network."
  value       = "${docker_container.redis.name}:6379"
}

output "container_id" {
  description = "Redis container ID."
  value       = docker_container.redis.id
}

output "volume_name" {
  description = "Data volume name."
  value       = docker_volume.redis_data.name
}

output "image_id" {
  description = "Redis image ID."
  value       = docker_image.redis.image_id
}
