class UserAuthorizer < ApplicationAuthorizer
  class << self
    def creatable_by?(user)
      user.guest? || user.admin?
    end

    def updatable_by?(user)
      ! user.guest?
    end
  end

  def updatable_by?(user)
    resource.id == user.id || user.admin?
  end
end
