# Module `web-service`

Generic HTTP container: one image, one published host port, one or more networks, and environment variables.

## Usage

```hcl
module "api" {
  source = "./modules/web-service"

  name      = "cs554-p3-dev-api"
  image_id  = data.docker_image.api.id
  host_port = 8091

  environment_variables = {
    REDIS_HOST = module.redis.hostname
  }

  networks = [
    { name = docker_network.frontend.name },
    { name = docker_network.backend.name },
  ]
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | required | Container name; also its DNS hostname |
| `image_id` | `string` | required | Image ID to run |
| `host_port` | `number` | required | Host port to publish (1024–65535) |
| `networks` | `list(object({ name = string, aliases = optional(list(string), []) }))` | required | Networks to attach (at least one) |
| `internal_port` | `number` | `3000` | Port the app listens on in the container |
| `host_ip` | `string` | `"127.0.0.1"` | Host IP to bind the port to |
| `environment_variables` | `map(string)` | `{}` | Environment variables. Stored in state, so no secrets |
| `restart_policy` | `string` | `"unless-stopped"` | `no`, `on-failure`, `always` or `unless-stopped` |
| `labels` | `map(string)` | `{}` | Docker labels |

## Outputs

| Name | Description |
|---|---|
| `container_name` | Container name |
| `container_id` | Container ID |
| `host_port` | Published host port |
| `url` | HTTP endpoint on the host |

## Notes

- Changing `restart_policy` updates the container in place.
- Changing the port, image, environment variables, name or networks replaces the container.
