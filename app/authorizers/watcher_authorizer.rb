class WatcherAuthorizer < ApplicationAuthorizer
  def deletable_by?(user)
    user == resource.user || user.admin?
  end
end
