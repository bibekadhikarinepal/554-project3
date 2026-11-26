# test: use with the "test" workspace. Nonsecret.
environment       = "test"
host_port         = 8092
project_name      = "cs554-p3"
host_bind_address = "127.0.0.1"
api_image         = "cs454-project3-api:1.0"
redis_image       = "redis:7.4.12-alpine"
redis_append_only = true
