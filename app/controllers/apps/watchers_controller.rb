class Apps::WatchersController < Apps::ApplicationController
  respond_to :html

  def destroy
    # TODO: strange. user_id and prams[:id]
    watcher = resource_app.watchers.find_by!(user_id: params[:id])
    authorize_action_for watcher
    watcher.destroy!
    flash[:success] = "That's sad. #{watcher.label} is no longer watcher."
    redirect_to root_path
  end
end

