class UsersController < ApplicationController
  respond_to :html

  authorize_actions_for User

  def index
    @users = User.page(params[:page]).per(current_user.per_page)
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
    authorize_action_for(@user)
  end

  def create
    @user = User.new user_params
    if @user.save
      flash[:success] = "#{@user.name} is now part of the team."
      sign_in(@user)
      redirect_to root_path
    else
      render :new
    end
  end

  def update
    @user = User.find(params[:id])
    @user.assign_attributes(user_params)
    authorize_action_for(@user)
    if @user.save
      flash[:success] = I18n.t('controllers.users.flash.update.success', name: @user.name)
      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  ##
  # Destroy the user pass in args
  #
  # @param [ String ] id the id of user we want delete
  #
  def destroy
    @user = User.find(params[:id])
    authorize_action_for(@user)
    UserDestroy.new(@user).destroy
    flash[:success] = I18n.t('controllers.users.flash.destroy.success', name: @user.name)
    redirect_to users_path
  end

  def unlink_github
    user.update_attributes :github_login => nil, :github_oauth_token => nil
    redirect_to user_path(user)
  end

  protected

  def user_params
    @user_params ||= params[:user] ? params.require(:user).permit(*user_permit_params) : {}
  end

  def user_permit_params
    @user_permit_params ||= [:name,:username, :email, :github_login, :per_page, :time_zone]
    @user_permit_params << :admin if current_user_or_guest.can?(:edit_user_admin_field, user_id: params[:id])
    @user_permit_params |= [:password, :password_confirmation] if user_password_params.values.all?{|pa| !pa.blank? }
    @user_permit_params
  end

  def user_password_params
    @user_password_params ||= params[:user] ? params.require(:user).permit(:password, :password_confirmation) : {}
  end

end

