# frozen_string_literal: true

if ENV["REDIS_URL"]
  settings = {
    url: ENV["REDIS_URL"],
    namespace: ENV["REDIS_NAMESPACE"]
  }

  Sidekiq.configure_server do |config|
    config.redis = settings
    # sidekiq pro features below
    # config.super_fetch!
    # config.reliable_scheduler!
    Yabeda::Prometheus::Exporter.start_metrics_server!
  end

  Sidekiq.configure_client do |config|
    config.redis = settings
  end

  # sidekiq pro features below
  # Sidekiq::Client.reliable_push! unless Rails.env.test?

  schedule_file = "config/schedule.yml"
  if File.exist?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end
else
  if Rails.env.development?
    Rails.application.config.active_job.queue_adapter = ENV["DEV_QUEUE_ADAPTER"] || :async
  else
    Rails.application.config.active_job.queue_adapter = :async
  end
end
