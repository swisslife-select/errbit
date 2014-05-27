class Apps::ApplicationController < ApplicationController
  helper_method :resource_app

private
  def resource_app
    @resource_app ||= current_user_or_guest.available_apps.detect_by_param!(params[:app_id])
  end
end
