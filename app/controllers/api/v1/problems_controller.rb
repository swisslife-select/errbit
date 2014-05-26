class Api::V1::ProblemsController < ApplicationController
  respond_to :json, :xml

  authorize_actions_for Problem

  def index
    problems = Problem.select %w{app_id app_name environment message problems.where first_notice_at last_notice_at resolved resolved_at notices_count}

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.parse(params[:start_date]).utc
      end_date = Time.parse(params[:end_date]).utc
      problems = problems.where(["first_notice_at <= ? AND (resolved_at IS NULL OR resolved_at >= ?)", end_date, start_date])
    end

    results = benchmark("[api/v1/problems_controller] query time") { problems.to_a }

    respond_to do |format|
      format.any(:html, :json) { render :json => Yajl.dump(results) } # render JSON if no extension specified on path
      format.xml  { render :xml  => results }
    end
  end

end
