locals {
  name_prefix = "${var.project_name}-${var.environment}"

  labels = {
    "project"      = var.project_name
    "environment"  = var.environment
    "managed-by"   = "terraform"
    "tf-workspace" = terraform.workspace
  }
}

# Prebuilt app image (docker build -t cs454-project3-api:1.0 ./app). Read only, not managed.
data "docker_image" "api" {
  name = var.api_image
}

# Private network for API <-> Redis. Internal: no access outside Docker.
resource "docker_network" "backend" {
  name     = "${local.name_prefix}-backend"
  driver   = "bridge"
  internal = true

  dynamic "labels" {
    for_each = local.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  lifecycle {
    # Stops a workspace from applying another environment's settings.
    precondition {
      condition     = terraform.workspace == "default" || terraform.workspace == var.environment
      error_message = "Workspace \"${terraform.workspace}\" does not match environment \"${var.environment}\". Run: terraform workspace select ${var.environment}  (or use the matching -var-file)."
    }
  }
}

# Host-facing network. Only the API joins it.
resource "docker_network" "frontend" {
  name   = "${local.name_prefix}-frontend"
  driver = "bridge"

  dynamic "labels" {
    for_each = local.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}

module "redis" {
  source = "./modules/redis"

  name         = "${local.name_prefix}-redis"
  image        = var.redis_image
  network_name = docker_network.backend.name
  append_only  = var.redis_append_only
  labels       = local.labels
}

module "api" {
  source = "./modules/web-service"

  name          = "${local.name_prefix}-api"
  image_id      = data.docker_image.api.id
  internal_port = 3000
  host_port     = var.host_port
  host_ip       = var.host_bind_address

  # Redis is reached by container name through Docker DNS.
  environment_variables = {
    SERVICE_NAME = "${local.name_prefix}-api"
    REDIS_HOST   = module.redis.hostname
    REDIS_PORT   = tostring(module.redis.port)
    PORT         = "3000"
  }

  networks = [
    { name = docker_network.frontend.name },
    { name = docker_network.backend.name },
  ]

  labels = local.labels
}
