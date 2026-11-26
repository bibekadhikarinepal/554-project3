variable "name" {
  description = "Container name; also its DNS hostname on the network."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_.-]{1,62}$", var.name))
    error_message = "name must be 2-63 characters: lowercase letters, digits, '.', '_' or '-'."
  }
}

variable "image" {
  description = "Redis image (explicit tag or digest, no :latest)."
  type        = string
  default     = "redis:7.4.12-alpine"

  validation {
    condition = (
      can(regex("@sha256:[0-9a-f]{64}$", var.image)) ||
      (can(regex(":[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image)) && !endswith(var.image, ":latest"))
    )
    error_message = "Pin the Redis image with an explicit tag (for example redis:7.4.12-alpine) or a @sha256 digest. ':latest' is not allowed."
  }
}

variable "network_name" {
  description = "Private network to join. No host port is published."
  type        = string
}

variable "network_aliases" {
  description = "Extra DNS names on the network."
  type        = list(string)
  default     = []
}

variable "volume_name" {
  description = "Data volume name. Defaults to <name>-data."
  type        = string
  default     = null
}

variable "append_only" {
  description = "Enable AOF persistence."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Docker labels."
  type        = map(string)
  default     = {}
}

variable "healthy_timeout_seconds" {
  description = "Seconds to wait for the Redis healthcheck to pass."
  type        = number
  default     = 60
}
