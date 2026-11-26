variable "host_port" {
  description = "Host port for the HTTP API (the only published port)."
  type        = number
  default     = 8080

  validation {
    condition     = var.host_port >= 1024 && var.host_port <= 65535 && floor(var.host_port) == var.host_port
    error_message = "host_port must be an unprivileged integer TCP port between 1024 and 65535."
  }
}

variable "environment" {
  description = "Environment label used in resource names. Must match the workspace name outside the default workspace."
  type        = string
  default     = "local"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "environment must be 2-12 lowercase letters/digits, starting with a letter."
  }
}

variable "project_name" {
  description = "Prefix for all resource names."
  type        = string
  default     = "cs554-p3"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,23}$", var.project_name))
    error_message = "project_name must be 2-24 characters: lowercase letters, digits, '-', starting with a letter."
  }
}

variable "host_bind_address" {
  description = "Host IP the API port binds to."
  type        = string
  default     = "127.0.0.1"
}

variable "api_image" {
  description = "Prebuilt API image (explicit tag or digest, no :latest)."
  type        = string
  default     = "cs454-project3-api:1.0"

  validation {
    condition = (
      can(regex("@sha256:[0-9a-f]{64}$", var.api_image)) ||
      (can(regex(":[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.api_image)) && !endswith(var.api_image, ":latest"))
    )
    error_message = "Pin api_image with an explicit tag (for example cs454-project3-api:1.0) or a @sha256 digest. ':latest' is not allowed."
  }
}

variable "redis_image" {
  description = "Redis image (explicit tag or digest, no :latest)."
  type        = string
  default     = "redis:7.4.12-alpine"
}

variable "redis_append_only" {
  description = "Enable Redis AOF persistence."
  type        = bool
  default     = true
}
