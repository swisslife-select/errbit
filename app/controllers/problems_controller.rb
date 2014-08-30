class ProblemsController < ApplicationController
  authorize_actions_for Problem

  before_filter :need_selected_problem, :only => [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  helper_method :selected_problems

  def index
    params_q = params.fetch(:q, {}).reverse_merge state_eq: 'unresolved', s: 'last_notice_at desc'
    @q = Problem.search(params_q)

    @problems = @q.result.for_apps(current_user.available_apps).preload(app: :issue_tracker)
    @problems = @problems.page(params[:page]).per(current_user.per_page) if request.format != :atom
  end

  def resolve_several
    selected_problems.each(&:resolve)
    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, :count => selected_problems.count)} been resolved."
    redirect_to :back
  end

  def unresolve_several
    selected_problems.each(&:unresolve)
    flash[:success] = "#{I18n.t(:n_errs_have, :count => selected_problems.count)} been unresolved."
    redirect_to :back
  end

  def destroy_several
    destroyed = selected_problems.destroy_all
    flash[:notice] = "#{I18n.t(:n_errs_have, :count => destroyed.length)} been deleted."
    redirect_to :back
  end

  #TODO: think about refactoring
  def selected_problems
    @selected_problems ||= Problem.where(id: err_ids)
  end

  def err_ids
    params.fetch(:problems, []).compact
  end

  protected

  ##
  # Redirect :back if no errors selected
  #
  def need_selected_problem
    if err_ids.empty?
      flash[:notice] = I18n.t('controllers.problems.flash.no_select_problem')
      redirect_to :back
    end
  end
end

