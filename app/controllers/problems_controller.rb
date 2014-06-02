class ProblemsController < ApplicationController
  authorize_actions_for Problem

  before_filter :need_selected_problem, :only => [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  helper_method :selected_problems

  def index
    params_q = params.fetch(:q, {}).reverse_merge resolved_eq: false, s: 'last_notice_at desc'
    @q = Problem.search(params_q)

    @problems = @q.result.for_apps(current_user.available_apps).preload(app: :issue_tracker)
    @problems = @problems.page(params[:page]).per(current_user.per_page) if request.format != :atom
  end

  def resolve_several
    selected_problems.each(&:resolve!)
    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, :count => selected_problems.count)} been resolved."
    redirect_to :back
  end

  def unresolve_several
    selected_problems.each(&:unresolve!)
    flash[:success] = "#{I18n.t(:n_errs_have, :count => selected_problems.count)} been unresolved."
    redirect_to :back
  end

  ##
  # Action to merge several Problem in One problem
  #
  # @param [ Array<String> ] :problems the list of problem ids
  #
  def merge_several
    if selected_problems.length < 2
      flash[:notice] = I18n.t('controllers.problems.flash.need_two_errors_merge')
    else
      ProblemMerge.new(selected_problems).merge
      flash[:notice] = I18n.t('controllers.problems.flash.merge_several.success', :nb => selected_problems.count)
    end
    redirect_to :back
  end

  def unmerge_several
    all = selected_problems.map(&:unmerge!).flatten
    flash[:success] = "#{I18n.t(:n_errs_have, :count => all.length)} been unmerged."
    redirect_to :back
  end

  def destroy_several
    nb_problem_destroy = ProblemDestroy.execute(selected_problems)
    flash[:notice] = "#{I18n.t(:n_errs_have, :count => nb_problem_destroy)} been deleted."
    redirect_to :back
  end

  #TODO: think about refactoring
  def selected_problems
    @selected_problems ||= Problem.find(err_ids)
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

