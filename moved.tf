# Resources moved from the root module into modules/ without being recreated.

moved {
  from = docker_image.redis
  to   = module.redis.docker_image.redis
}

moved {
  from = docker_volume.redis_data
  to   = module.redis.docker_volume.redis_data
}

moved {
  from = docker_container.redis
  to   = module.redis.docker_container.redis
}

moved {
  from = docker_container.api
  to   = module.api.docker_container.service
}
