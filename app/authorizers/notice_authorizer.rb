class NoticeAuthorizer < ApplicationAuthorizer
  class << self
    def default(adjective, user)
      ! user.guest?
    end

    def creatable_by?(user)
      true
    end
  end
end
