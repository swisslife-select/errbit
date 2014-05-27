class Apps::ApplicationController < ApplicationController
  helper_method :resource_app

  before_filter do
    forbid(:app) unless current_user_or_guest.can_read?(resource_app)
  end

private
  def resource_app
    #if need 404
    #@resource_app ||= current_user_or_guest.available_apps.detect_by_param!(params[:app_id])
    @resource_app ||= App.detect_by_param!(params[:app_id])
  end
end
