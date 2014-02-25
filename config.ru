# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'sidekiq/web'

use Rack::Deflater

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == Errbit::Config.sidekiq_admin && password == Errbit::Config.sidekiq_admin_password
end

run Rack::URLMap.new(
  "/" => Rails.application,
  "/sidekiq" => Sidekiq::Web
)
