class AppAuthorizer < ApplicationAuthorizer
  class << self
    def readable_by?(user)
      ! user.guest?
    end
  end

  def readable_by?(user)
    user.available_apps.exists?(resource)
  end
end
