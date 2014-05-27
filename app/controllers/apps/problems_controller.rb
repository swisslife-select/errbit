class Apps::ProblemsController < Apps::ApplicationController
  authorize_actions_for Problem

  expose(:problem) {
    resource_app.problems.detect_by_param!(params[:id])
  }

  def show
    @notices  = problem.notices.reverse_ordered.page(params[:notice]).per(1)
    @notice   = @notices.first
    @comment = Comment.new
  end

  def create_issue
    IssueTracker.update_url_options(request)
    issue_creation = IssueCreation.new(problem, current_user, params[:tracker])

    unless issue_creation.execute
      flash[:error] = issue_creation.errors.full_messages.join(', ')
    end

    redirect_to app_problem_path(resource_app, problem)
  end

  def unlink_issue
    problem.update_attribute :issue_link, nil
    redirect_to app_problem_path(resource_app, problem)
  end

  def resolve
    problem.resolve!
    flash[:success] = 'Great news everyone! The err has been resolved.'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(resource_app)
  end

  def destroy_all
    nb_problem_destroy = ProblemDestroy.execute(resource_app.problems)
    flash[:success] = "#{I18n.t(:n_errs_have, :count => nb_problem_destroy)} been deleted."
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(resource_app)
  end
end

