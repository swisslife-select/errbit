class NoticesController < ApplicationController
  class ParamsError < StandardError; end

  authorize_actions_for Notice

  rescue_from ParamsError, :with => :bad_params

  def create
    # params[:data] if the notice came from a GET request, raw_post if it came via POST
    report = ErrorReport.new(notice_params)

    if report.valid?
      report.generate_notice!
      api_xml = report.notice.to_xml(:only => false, :methods => [:id]) do |xml|
        xml.url locate_url(report.notice.id, :host => Errbit::Config.host)
      end
      render :xml => api_xml
    else
      render :text => "Your API key is unknown", :status => 422
    end
  end

  # Redirects a notice to the problem page. Useful when using User Information at Airbrake gem.
  def locate
    problem = Notice.find(params[:id]).problem
    redirect_to app_problem_path(problem.app, problem)
  end

  private

  def notice_params
    return @notice_params if @notice_params

    @notice_params = NoticeAttributesFetcher.from_request request

    raise ParamsError.new('Incorrect a data param in GET or raw POST data') if @notice_params.blank?
    @notice_params
  end

  def bad_params(exception)
    render :text => exception.message, :status => :bad_request
  end

end
