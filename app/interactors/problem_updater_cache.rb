class ProblemUpdaterCache
  def initialize(problem, notice=nil)
    @problem = problem
    @notice = notice
  end
  attr_reader :problem

  ##
  # Update cache information about child associate to this problem
  #
  # update the notices count, and some notice informations
  #
  # @return [ Problem ] the problem with this update
  #
  def update
    update_notices_count
    update_notices_cache
    problem
  end

  private

  def update_notices_count
    if @notice
      problem.inc(:notices_count, 1)
    else
      problem.update_attribute(
        :notices_count, problem.notices.count
      )
    end
  end

  ##
  # Update problem statistique from some notice information
  #
  def update_notices_cache
    first_notice = notices.first
    last_notice = notices.last
    notice ||= @notice || first_notice

    attrs = {}
    attrs[:first_notice_at] = first_notice.created_at if first_notice
    attrs[:last_notice_at] = last_notice.created_at if last_notice
    attrs.merge!(
      :message     => notice.message,
      :where       => notice.where
    ) if notice
    problem.update_attributes!(attrs)
  end

  def notices
    @notices ||= @notice ? [@notice].sort(&:created_at) : problem.notices.order("created_at ASC")
  end
end
