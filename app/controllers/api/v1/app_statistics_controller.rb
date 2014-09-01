class Api::V1::AppStatisticsController < ApplicationController
  def show
    @app = App.find params[:id]
    authorize_action_for @app
  end
end
