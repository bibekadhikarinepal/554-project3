terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6.0" # pins major and minor (4.6.x)
    }
  }
}

# Uses DOCKER_HOST if set, otherwise the default local Docker socket.
provider "docker" {}
