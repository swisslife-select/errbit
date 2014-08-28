class Apps::ProblemsController < Apps::ApplicationController
  authorize_actions_for Problem

  def show
    @problem = resource_app.problems.detect_by_param!(params[:id])
    @notice = @problem.notices.for_show(params[:notice_id])
    @comment = Comment.new
  end

  def create_issue
    @problem = resource_app.problems.detect_by_param!(params[:id])
    IssueTracker.update_url_options(request)
    issue_creation = IssueCreation.new(@problem, current_user, params[:tracker])

    unless issue_creation.execute
      flash[:error] = issue_creation.errors.full_messages.join(', ')
    end

    redirect_to app_problem_path(resource_app, @problem)
  end

  def unlink_issue
    @problem = resource_app.problems.detect_by_param!(params[:id])
    @problem.update_attribute :issue_link, nil
    redirect_to app_problem_path(resource_app, @problem)
  end

  def resolve
    @problem = resource_app.problems.detect_by_param!(params[:id])
    @problem.resolve!
    flash[:success] = 'Great news everyone! The err has been resolved.'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(resource_app)
  end

  def destroy_all
    destroyed = resource_app.problems.destroy_all
    flash[:success] = "#{I18n.t(:n_errs_have, :count => destroyed.length)} been deleted."
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(resource_app)
  end
end

