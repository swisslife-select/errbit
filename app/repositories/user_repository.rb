module UserRepository
  extend ActiveSupport::Concern

  included do
    scope :with_not_blank_email, -> { where("email IS NOT NULL AND email != ''") }
    scope :ordered, -> { order('name ASC') }
  end

  def available_apps
    scope = admin? ? App.scoped : apps
    scope.includes(:issue_tracker, :notification_service, :last_deploy)
  end
end
