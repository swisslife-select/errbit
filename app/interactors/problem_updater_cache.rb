class ProblemUpdaterCache
  def initialize(problem, notice)
    @problem = problem
    @notice = notice
  end
  attr_reader :problem, :notice

  ##
  # Update cache information about child associate to this problem
  #
  # update the notices count, and some notice informations
  #
  # @return [ Problem ] the problem with this update
  #
  def update
    #update_notices_count ## Problem merging are deprecated
    update_notices_cache
    problem
  end

  private

  ##
  # Update problem statistique from some notice information
  #
  def update_notices_cache
    attrs = {
      :last_notice_at => notice.created_at,
      :message     => notice.message,
      :where       => notice.where
    }
    problem.update_attributes!(attrs)
  end
end
