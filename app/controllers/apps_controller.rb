class AppsController < ApplicationController
  authorize_actions_for App

  before_filter :parse_email_at_notices_or_set_default, :only => [:create, :update]
  before_filter :parse_notice_at_notices_or_set_default, :only => [:create, :update]
  respond_to :html

  helper_method :selected_problems

  def index
    @q = current_user_or_guest.available_apps.search(params[:q])
    @q.sorts = 'unresolved_problems_count desc' if @q.sorts.empty?
    @apps = @q.result(distinct: true).includes(:issue_tracker, :notification_service)
    #TODO: think about includes App#last_deploy. AR load unnecessary deploys to RAM in includes(:last_deploy) case.
    #TODO: try fix N+1 with last_deploy
  end

  def show
    @app = current_user_or_guest.available_apps.detect_by_param! params[:id]
    params_q = params.fetch(:q, {}).reverse_merge resolved_eq: false, s: 'last_notice_at desc'
    @q = @app.problems.search(params_q)
    @problems = @q.result.page(params[:page]).per(current_user.per_page)
    #FIXME
    @problems = @app.problems.unresolved.ordered if request.format == :atom
  end

  def new
    @app = App.new
    plug_params(@app)
  end

  def create
    @app = current_user_or_guest.available_apps.new params[:app]

    if @app.save
      redirect_to app_url(@app), :flash => { :success => I18n.t('controllers.apps.flash.create.success') }
    else
      flash[:error] = I18n.t('controllers.apps.flash.create.error')
      render :new
    end
  end

  def update
    @app = current_user_or_guest.available_apps.detect_by_param! params[:id]
    if @app.update params[:app]
      redirect_to app_url(@app), :flash => { :success => I18n.t('controllers.apps.flash.update.success') }
    else
      flash[:error] = I18n.t('controllers.apps.flash.update.error')
      render :edit
    end
  end

  def edit
    @app = current_user_or_guest.available_apps.detect_by_param! params[:id]
    plug_params(@app)
  end

  def destroy
    @app = current_user_or_guest.available_apps.detect_by_param! params[:id]
    if @app.destroy
      redirect_to apps_url, :flash => { :success => I18n.t('controllers.apps.flash.destroy.success') }
    else
      flash[:error] = I18n.t('controllers.apps.flash.destroy.error')
      render :show
    end
  end

  def regenerate_api_key
    @app = current_user_or_guest.available_apps.detect_by_param! params[:id]
    @app.regenerate_api_key!
    redirect_to edit_app_path(@app)
  end

  #TODO: think about refactoring
  def selected_problems
    @selected_problems ||= Problem.find(err_ids)
  end

  def err_ids
    params.fetch(:problems, []).compact
  end

  protected
    def plug_params app
      donor = App.find_by id: params[:copy_attributes_from]
      AppCopy.deep_copy_attributes(app, donor) if donor

      app.watchers.build if app.watchers.none?
      app.issue_tracker = IssueTracker.new unless app.issue_tracker_configured?
      app.notification_service = NotificationService.new unless app.notification_service_configured?
    end

    # email_at_notices is edited as a string, and stored as an array.
    def parse_email_at_notices_or_set_default
      if params[:app] && val = params[:app][:email_at_notices]
        # Sanitize negative values, split on comma,
        # strip, parse as integer, remove all '0's.
        # If empty, set as default and show an error message.
        email_at_notices = val.gsub(/-\d+/,"").split(",").map{|v| v.strip.to_i }.reject{|v| v == 0}
        if email_at_notices.any?
          params[:app][:email_at_notices] = email_at_notices
        else
          default_array = params[:app][:email_at_notices] = Errbit::Config.email_at_notices
          flash[:error] = "Couldn't parse your notification frequency. Value was reset to default (#{default_array.join(', ')})."
        end
      end
    end

    def parse_notice_at_notices_or_set_default
      if params[:app][:notification_service_attributes] && val = params[:app][:notification_service_attributes][:notify_at_notices]
        # Sanitize negative values, split on comma,
        # strip, parse as integer, remove all '0's.
        # If empty, set as default and show an error message.
        notify_at_notices = val.gsub(/-\d+/,"").split(",").map{|v| v.strip.to_i }
        if notify_at_notices.any?
          params[:app][:notification_service_attributes][:notify_at_notices] = notify_at_notices
        else
          default_array = params[:app][:notification_service_attributes][:notify_at_notices] = Errbit::Config.notify_at_notices
          flash[:error] = "Couldn't parse your notification frequency. Value was reset to default (#{default_array.join(', ')})."
        end
      end
    end
end
