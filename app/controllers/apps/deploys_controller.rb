class Apps::DeploysController < Apps::ApplicationController
  authorize_actions_for Deploy

  def index
    @deploys = resource_app.deploys.by_created_at.page(params[:page]).per(10)
  end

  def show
    @deploy = resource_app.deploys.find params[:id]
  end
end

