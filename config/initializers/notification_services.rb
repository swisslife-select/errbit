Dir.glob(Rails.root.join('app/models/notification_services/*.rb')).each {|t| require t }

# Include nested notification services models
include NotificationServices
