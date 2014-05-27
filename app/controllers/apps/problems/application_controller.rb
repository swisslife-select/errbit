class Apps::Problems::ApplicationController < Apps::ApplicationController
  helper_method :resource_problem

  before_filter do
    forbid(:problem) unless current_user_or_guest.can_read?(resource_problem)
  end

private
  def resource_problem
    # for 404
    #@resource_problem ||= resource_app.problems.find(params[:problem_id])
    @resource_problem ||= Problem.find(params[:problem_id])
  end
end
