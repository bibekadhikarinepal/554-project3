# HTTP service container: one image, one published port, one or more networks.

resource "docker_container" "service" {
  name    = var.name
  image   = var.image_id
  restart = var.restart_policy
  env     = [for key in sort(keys(var.environment_variables)) : "${key}=${var.environment_variables[key]}"]

  ports {
    internal = var.internal_port
    external = var.host_port
    ip       = var.host_ip
    protocol = "tcp"
  }

  dynamic "networks_advanced" {
    for_each = var.networks
    content {
      name    = networks_advanced.value.name
      aliases = networks_advanced.value.aliases
    }
  }

  destroy_grace_seconds = 5

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}
