class AppAuthorizer < ApplicationAuthorizer
  class << self
    def readable_by?(user)
      ! user.guest?
    end
  end
end
