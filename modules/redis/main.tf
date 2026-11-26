# Redis with a named volume on a private network. No host port by design.

locals {
  volume_name = coalesce(var.volume_name, "${var.name}-data")

  server_args = var.append_only ? ["redis-server", "--appendonly", "yes", "--appendfsync", "everysec"] : ["redis-server"]
}

resource "docker_image" "redis" {
  name         = var.image
  keep_locally = true # shared by environments; keep it on destroy
}

resource "docker_volume" "redis_data" {
  name = local.volume_name

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}

resource "docker_container" "redis" {
  name    = var.name
  image   = docker_image.redis.image_id
  command = local.server_args
  restart = "unless-stopped"

  networks_advanced {
    name    = var.network_name
    aliases = var.network_aliases
  }

  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "2s"
    timeout  = "1s"
    retries  = 10
  }

  # Wait until healthy, so the API is created only after Redis is ready.
  wait         = true
  wait_timeout = var.healthy_timeout_seconds

  destroy_grace_seconds = 10 # lets Redis flush data before removal

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}
