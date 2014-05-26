class ApplicationController < ActionController::Base
  protect_from_forgery
  ensure_authorization_performed unless: :devise_controller?

  before_filter :authenticate_user_from_token!
  before_filter :set_time_zone

  # Devise override - After login, if there is only one app,
  # redirect to that app's path instead of the root path (apps#index).
  def stored_location_for(resource)
    location = super || root_path
    (location == root_path && current_user.apps.count == 1) ? app_path(current_user.apps.first) : location
  end

  rescue_from ActionController::RedirectBackError, :with => :redirect_to_root

  class StrongParametersWithEagerAttributesStrategy < DecentExposure::StrongParametersStrategy
    def attributes
      super
      @attributes ||= params[inflector.param_key] || {}
    end
  end

  decent_configuration do
    strategy StrongParametersWithEagerAttributesStrategy
  end

protected


  def current_user_or_guest
    return current_user if current_user.present?
    @guest ||= User::Guest.new
  end

  def redirect_to_root
    redirect_to(root_path)
  end

  def set_time_zone
    Time.zone = current_user.time_zone if user_signed_in?
  end

  def authenticate_user_from_token!
    user_token = params[User.token_authentication_key].presence
    user       = user_token && User.find_by(authentication_token: user_token)

    if user
      sign_in user, store: false
    end
  end

  def authority_forbidden(error)
    Authority.logger.warn(error.message)
    if current_user_or_guest.guest?
      redirect_to new_user_session_path
    else
      flash[:error] = "Sorry, you don't have permission to do that"
      redirect_to root_path
    end
  end
end
