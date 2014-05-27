class Apps::Problems::ApplicationController < Apps::ApplicationController
  helper_method :resource_problem

private
  def resource_problem
    @resource_problem ||= resource_app.problems.find(params[:problem_id])
  end
end
