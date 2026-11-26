# Module `redis`

Private Redis on an existing Docker network: pinned image, named volume at `/data`, and a health-checked container. The module has no host-port input, so Redis cannot be published to the host.

## Usage

```hcl
module "redis" {
  source = "./modules/redis"

  name         = "cs554-p3-dev-redis"
  network_name = docker_network.backend.name
  image        = "redis:7.4.12-alpine"
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | required | Container name; also its DNS hostname |
| `network_name` | `string` | required | Private network to join |
| `image` | `string` | `"redis:7.4.12-alpine"` | Explicit tag or `@sha256` digest; `:latest` is rejected |
| `network_aliases` | `list(string)` | `[]` | Extra DNS names |
| `volume_name` | `string` | `"<name>-data"` | Data volume name |
| `append_only` | `bool` | `true` | Enable AOF persistence |
| `labels` | `map(string)` | `{}` | Docker labels |
| `healthy_timeout_seconds` | `number` | `60` | Seconds to wait for the health check |

## Outputs

| Name | Description |
|---|---|
| `hostname` | DNS name of Redis (the container name) |
| `port` | `6379` (not published) |
| `address` | `<hostname>:6379` |
| `container_id` | Redis container ID |
| `volume_name` | Data volume name |
| `image_id` | Redis image ID |

## Notes

- `wait = true` holds the apply until Redis is healthy, so dependent containers start after it.
- `terraform destroy` deletes the volume and its data. The image is kept (`keep_locally = true`).
