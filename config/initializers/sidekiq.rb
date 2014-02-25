configure_db_pool_for_sidekiq = Proc.new do
  config = Rails.application.config.database_configuration[Rails.env]
  config['pool'] = Sidekiq.options[:concurrency] + 2
  ActiveRecord::Base.establish_connection(config)
end

Sidekiq.configure_server do |config|
  config.redis = { namespace: Errbit::Config.sidekiq_namespace }

  configure_db_pool_for_sidekiq.call
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: Errbit::Config.sidekiq_namespace }
end
