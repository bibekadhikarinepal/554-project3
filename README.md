# Reproducible Infrastructure with Terraform

Terraform configuration for an HTTP API and a Redis datastore on the local Docker engine, using the kreuzwerker/docker provider. No cloud account is required.

## Architecture

```text
  curl / browser
        |
        |  http://127.0.0.1:<host_port>   (only port published to the host)
        v
+-------------------+
|   API container   |   networks: frontend + backend
|   node, port 3000 |
+-------------------+
        |
        |  REDIS_HOST = cs554-p3-<env>-redis, port 6379 (Docker DNS)
        v
+-------------------+
|  Redis container  |   network: backend only (internal, no host port)
|  redis:7.4.12     |
+-------------------+
        |
        |  mounted at /data
        v
  named volume: cs554-p3-<env>-redis-data
```

- **Networks:** the API joins `frontend`, which publishes its host port, and `backend`, which it shares with Redis.
- **Isolation:** `backend` is an internal network, so Redis has no host port and no internet access.
- **What Terraform manages:** both networks, the volume, the Redis image and both containers. The API image is built beforehand with `docker build`, and Terraform only reads it.
- **Naming:** resources are named `cs554-p3-<environment>-<role>`.

## Repository structure

```text
main.tf, variables.tf, outputs.tf, versions.tf   Root configuration
moved.tf                      Address mapping from the module refactor
terraform.tfvars.example      Example variable file
modules/redis/                Redis container, image and volume
modules/web-service/          Generic HTTP container (used for the API)
environments/                 dev and test variable files
app/                          Application from Exercise 03 (unchanged)
scripts/smoke-test.sh         HTTP test
scripts/drift-attributes.py   Drift analysis helper
evidence/                     Command output for each requirement
```

## Prerequisites

| Tool | Tested version |
|---|---|
| Docker Engine (Docker Desktop) | 28.1.1 |
| Terraform | 1.13.4 (1.5 or later required) |
| kreuzwerker/docker provider | 4.6.0 (`~> 4.6.0`, locked in `.terraform.lock.hcl`) |
| curl | 8.7.1 |
| Operating system | macOS 14.6. Linux works the same way; on Windows, use WSL2 |

The first run needs internet access to download the provider and container images.

**Ports:** baseline 8081 (8082 after the Part B change), dev 8091, test 8092. Any free port from 1024 to 65535 can be used.

## Setup and teardown

```bash
# 1. Build the application image
docker build -t cs454-project3-api:1.0 ./app

# 2. Configure
cp terraform.tfvars.example terraform.tfvars

# 3. Provision
terraform init
terraform fmt -recursive -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# 4. Test
terraform output api_url
scripts/smoke-test.sh

# 5. Tear down
terraform destroy
```

The smoke test sends three requests. It passes when every response is HTTP 200, `redisError` is null, and `redisCount` increases by one each time.

## Part A: Declare and provision

| Requirement | Implementation |
|---|---|
| Application container | `module.api` (`modules/web-service`) |
| Redis container | `module.redis` (`redis:7.4.12-alpine`, with a health check) |
| Private network | `docker_network.backend` (`internal = true`) |
| Named volume | `docker_volume.redis_data`, mounted at `/data` |
| App-to-Redis configuration | `REDIS_HOST` is set to the Redis container name, which Docker DNS resolves |
| Configurable host port | `var.host_port`, mapped to container port 3000 and bound to 127.0.0.1 |

- **Port exposure:** only the API publishes a port. The Redis module has no port input.
- **Pinning:** images use explicit tags, and validation rejects `:latest`. The provider is pinned to `~> 4.6.0`.
- **Paths:** no machine-specific paths are used.
- **Startup order:** the API depends on the Redis module's output, and Redis uses `wait = true`. Terraform therefore creates the API only after Redis is healthy. The app also connects to Redis on every request, so a request made before Redis is ready returns a `redisError` and the next request succeeds.

**Evidence:**

| File | Shows |
|---|---|
| [01](evidence/01-init-fmt-validate.txt) | `init`, `fmt` and `validate` |
| [02](evidence/02-plan.txt) | `plan` |
| [03](evidence/03-apply.txt) | `apply` |
| [04](evidence/04-http-test.txt) | HTTP test and isolation checks |

## Part B: Parameterize and evolve

| Variable | Default | Description |
|---|---|---|
| `host_port` | 8080 | API host port (1024–65535) |
| `environment` | local | Name label; must match the workspace for dev/test |
| `project_name` | cs554-p3 | Name prefix |
| `host_bind_address` | 127.0.0.1 | Host interface for the API port |
| `api_image` | cs454-project3-api:1.0 | Explicit tag or digest |
| `redis_image` | redis:7.4.12-alpine | Explicit tag or digest |
| `redis_append_only` | true | Redis AOF persistence |

`terraform.tfvars.example` provides the example values. The main output is `api_url`, the API endpoint. Other outputs give the container and network names, the volume and the Redis address.

### Controlled change: `host_port` 8081 → 8082 ([05](evidence/05-controlled-change.txt))

```bash
sed -i.bak 's/^host_port = 8081/host_port = 8082/' terraform.tfvars && rm terraform.tfvars.bak
terraform plan -out=change.tfplan
terraform show -no-color change.tfplan > change-plan.txt
terraform apply change.tfplan
scripts/smoke-test.sh
```

**Result:** `1 to add, 0 to change, 1 to destroy`.

- The API container was **replaced** (`external = 8081 -> 8082 # forces replacement`).
- The networks, volume and Redis container were unchanged, and the Redis count continued.
- The endpoint moved to port 8082.

**Why it was replaced:** Docker cannot change the port mappings of an existing container, so the provider has to recreate it. Settings that Docker can change in place, such as the restart policy, produce an in-place update instead.

## Part C: State, persistence and lifecycle

### State ([06](evidence/06-state-list.txt))

```text
data.docker_image.api
docker_network.backend
docker_network.frontend
module.api.docker_container.service
module.redis.docker_container.redis
module.redis.docker_image.redis
module.redis.docker_volume.redis_data
```

Terraform owns six resources: two networks, two containers, the volume and the Redis image. `data.docker_image.api` is a read-only lookup; the API image is not managed by Terraform.

### Persistence ([07](evidence/07-persistence-test.txt))

```bash
terraform plan -replace=module.api.docker_container.service -out=replace.tfplan
terraform apply replace.tfplan
scripts/smoke-test.sh
```

| | API container | Redis container | Volume created | redisCount |
|---|---|---|---|---|
| Before | a9b428930d7a | 197347c8867c | 00:50:42Z | 12 |
| After | f2d8c3bb45da | 197347c8867c | 00:50:42Z | 13 |

Only the API container changed. Redis and its volume were untouched, so the count continued.

### Redis durability

The test above does not restart Redis, so the count could have survived in memory alone. Proving durability requires three steps:

1. Replace the Redis container itself while keeping the volume, with persistence enabled (AOF is on here): `terraform apply -replace=module.redis.docker_container.redis`.
2. Confirm that the count continues.
3. For a stronger result, stop Redis with `docker kill -s KILL` so it cannot save on shutdown, and run a control with a fresh volume, where the count should restart at 1.

### Configuration vs state

- **Configuration** (`.tf` and `.tfvars` files) is the desired infrastructure.
- **State** (`terraform.tfstate`) is Terraform's record of the objects it created, mapping each resource address to a Docker ID.
- **How they meet:** `plan` refreshes the state from the real objects, then compares it with the configuration.
- **Not committed:** state is git-ignored because it is machine-specific and stores input values in plain text.

### Changes outside Terraform

The next `plan` reports "Objects have changed outside of Terraform" and proposes whatever restores the configuration: an in-place update, a replacement, or a re-create. Changes that Terraform does not track, such as data inside Redis, are not detected.

### Destroy ([08](evidence/08-destroy.txt))

`terraform destroy` removes all six resources, the API first. Verification shows an empty state and no remaining containers, networks or volumes.

- **Volume:** the named volume and its data are deleted. For data that must persist, use `prevent_destroy` or a separate state.
- **Images:** the Redis image remains because of `keep_locally = true`, and the API image remains because Terraform does not manage it.

## Part D: Terraform vs Docker Compose

| | Docker Compose | Terraform |
|---|---|---|
| Change preview | None | `plan` shows each create, update or replacement, with the reason |
| Record of resources | Container labels only | State file |
| Drift detection | No | Yes |
| Reuse | Compose files, profiles | Modules with typed inputs and outputs |
| Scope | A single Docker host | Any provider (cloud, DNS, Kubernetes) |
| Best suited for | Local development | Provisioning and changing environments |

### Cloud equivalents 

| Concept | This project | AWS | Azure |
|---|---|---|---|
| Container workload | API container | ECS on Fargate | Azure Container Apps |
| Network isolation | Frontend network + internal backend network | VPC with public and private subnets, security groups | VNet with subnets and NSGs |
| Persistent storage | Named volume for Redis | ElastiCache for Redis (or EBS) | Azure Cache for Redis (or Managed Disks) |
| External endpoint | 127.0.0.1:host_port | Application Load Balancer | Container Apps ingress or Application Gateway |

## Part E: Evidence and repository hygiene

- **Evidence:** `evidence/` contains the command output for each requirement. See [evidence/README.md](evidence/README.md).
- **Excluded from Git:** `.gitignore` excludes `.terraform/`, state files, saved plans, local `.tfvars` files and credential files.
- **Committed on purpose:**
  - `terraform.tfvars.example` and `environments/*.tfvars` (nonsecret values only);
  - `.terraform.lock.hcl`, with provider checksums for macOS, Linux and Windows.
 

## CS 554 requirements

### Modules

| Module | Purpose |
|---|---|
| `modules/redis` | Redis image, volume and container. It has no host-port input |
| `modules/web-service` | Generic single-port HTTP container |

Each module's README documents its inputs and outputs. `moved.tf` maps the original root addresses to the module addresses, so existing resources are moved in the state rather than recreated.

### dev and test environments ([09](evidence/cs554/09-dev-test-environments.txt))

| | dev | test |
|---|---|---|
| Variable file | `environments/dev.tfvars` | `environments/test.tfvars` |
| Resource names | `cs554-p3-dev-*` | `cs554-p3-test-*` |
| Host port | 8091 | 8092 |
| Workspace | `dev` (own state file) | `test` (own state file) |

```bash
terraform workspace select -or-create dev
terraform apply -var-file=environments/dev.tfvars
terraform destroy -var-file=environments/dev.tfvars

terraform workspace select -or-create test
terraform apply -var-file=environments/test.tfvars
terraform destroy -var-file=environments/test.tfvars
```

Both environments share the same code. A precondition requires the workspace name to match `environment`, so applying `test.tfvars` in the `dev` workspace fails before any change is made.

### Drift experiment ([10](evidence/cs554/10-drift-experiment.txt))

| | Manual change | Expected | Observed | Recovery |
|---|---|---|---|---|
| 1 | `docker update --restart=no` | In-place update of `restart` | As expected: `0 to add, 1 to change, 0 to destroy` | `apply`; same container ID |
| 2 | `docker rm -f` on the API | Container re-created | As expected: `1 to add`; Redis count continued | `apply` |

**Discrepancy:** `plan -refresh-only` also flagged objects that had not changed. An attribute-level diff (`scripts/drift-attributes.py`) showed this was only provider normalization (null vs empty values). The normal plan is the reliable drift check.

**Recovery options:**

- `apply` to revert to the configuration;
- update the configuration to keep an intended manual change;
- `apply -refresh-only` for differences that affect only the state;
- `import` for objects that were recreated by hand.

**Prevention:** avoid manual changes, and run `terraform plan -detailed-exitcode` on a schedule. Exit code 2 means drift.

### State isolation, secrets and collaboration

- **State isolation:** workspaces give each environment its own state from one codebase, and the precondition prevents applying to the wrong workspace. For production, use separate directories and backends with their own access control.
- **Secrets:** none are used here. A secret passed as an environment variable would be stored in plain text in state and plan files; `sensitive` only masks CLI output. Prefer:
  - injecting values at run time (`TF_VAR_*` from a secret manager);
  - ephemeral or write-only values;
  - references to AWS Secrets Manager or Azure Key Vault.
- **Collaboration:** local state cannot be shared or locked across machines. Teams should:
  - use a remote backend with locking (S3, Azure Blob Storage or HCP Terraform);
  - commit the lock file, never the state;
  - review a saved plan before applying;
  - use `moved` blocks when renaming resources.
 

## References

- Course exercises (Exercise 03, Exercise 06, project-3-starter): https://github.com/UAH-Computer-Science/cs454-Course-Exercises
- Terraform CLI: https://developer.hashicorp.com/terraform/cli
- kreuzwerker/docker provider: https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
- Redis persistence: https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/
