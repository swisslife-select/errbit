class WatchersController < ApplicationController
  respond_to :html

  authorize_actions_for Watcher

  expose(:app) do
    App.find(params[:app_id])
  end

  expose(:watcher) do
    app.watchers.where(:user_id => params[:id]).first
  end

  def destroy
    app.watchers.delete(watcher)
    flash[:success] = "That's sad. #{watcher.label} is no longer watcher."
    redirect_to root_path
  end
end

