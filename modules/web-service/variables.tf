variable "name" {
  description = "Container name; also its DNS hostname."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_.-]{1,62}$", var.name))
    error_message = "name must be 2-63 characters: lowercase letters, digits, '.', '_' or '-'."
  }
}

variable "image_id" {
  description = "Image ID to run."
  type        = string
}

variable "internal_port" {
  description = "Port the app listens on inside the container."
  type        = number
  default     = 3000
}

variable "host_port" {
  description = "Host port to publish (1024-65535)."
  type        = number

  validation {
    condition     = var.host_port >= 1024 && var.host_port <= 65535 && floor(var.host_port) == var.host_port
    error_message = "host_port must be an unprivileged integer TCP port between 1024 and 65535."
  }
}

variable "host_ip" {
  description = "Host IP to bind the port to."
  type        = string
  default     = "127.0.0.1"

  validation {
    condition     = can(cidrhost("${var.host_ip}/32", 0))
    error_message = "host_ip must be an IPv4 address such as 127.0.0.1."
  }
}

variable "environment_variables" {
  description = "Container environment variables. Stored in state, so no secrets."
  type        = map(string)
  default     = {}
}

variable "networks" {
  description = "Networks to attach."
  type = list(object({
    name    = string
    aliases = optional(list(string), [])
  }))

  validation {
    condition     = length(var.networks) > 0
    error_message = "Attach the service to at least one network."
  }
}

variable "restart_policy" {
  description = "Docker restart policy."
  type        = string
  default     = "unless-stopped"

  validation {
    condition     = contains(["no", "on-failure", "always", "unless-stopped"], var.restart_policy)
    error_message = "restart_policy must be one of: no, on-failure, always, unless-stopped."
  }
}

variable "labels" {
  description = "Docker labels."
  type        = map(string)
  default     = {}
}
