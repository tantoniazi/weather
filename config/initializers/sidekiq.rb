require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL") { "redis://weather-redis:6379/0" },
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL") { "redis://weather-redis:6379/0" },
  }
end

Sidekiq.configure_server do |config|
  config.logger.level = Logger::INFO

  config.concurrency = 5

  # timeout and retry are not available in Sidekiq 8.0.7
  # config.timeout = 30
  # config.retry = 3
end
