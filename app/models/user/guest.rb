class User::Guest
  include Authority::UserAbilities

  def guest?
    true
  end

  def admin?
    false
  end

  def available_apps
    App.none
  end
end
