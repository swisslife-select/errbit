Airbrake.configure do |config|
  config.api_key = "---------"
  # Don't log error that causes 404 page
  config.ignore << "ActiveRecord::RecordNotFound"
end
