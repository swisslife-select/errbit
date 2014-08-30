class ResolvedProblemClearer

  ##
  # Clear all problem already resolved
  #
  def execute
    nb_problem_resolved.tap { |nb|
      if nb > 0
        criteria.each do |problem|
          problem.destroy
        end
      end
    }
  end

  private

  def nb_problem_resolved
    @count ||= criteria.count
  end

  def criteria
    @criteria = Problem.resolved
  end
end
