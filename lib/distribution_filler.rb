module DistributionFiller
  class << self
    def perform
      puts Benchmark.measure {
        relation = Problem.preload(:errs)

        new_problems = relation.where("created_at >= ?", 1.month.ago)
        reindex_all(new_problems)
        old_problems = relation.where("created_at < ?",  1.month.ago)
        reindex_all(old_problems)
      }
    end

    def reindex_all(problem_scope)
      problem_scope.find_each do |problem|
        reindex(problem)
      end
    end

    def reindex(problem)
      messages = {}
      hosts = {}
      user_agents = {}

      problem.errs.each do |err|
        notices = err.notices.limit(100)
        notices.each do |n|
          begin
            inc_count_in_hash_for(n.message_signature, messages)
            inc_count_in_hash_for(n.host, hosts)
            inc_count_in_hash_for(n.user_agent_string, user_agents)
          rescue Psych::SyntaxError
            puts "Notice with id: #{n.id} have incorrect yaml inside request field"
          end
        end
      end


      problem.clear_message_distribution
      problem.clear_host_distribution
      problem.clear_user_agent_distribution

      problem.fill_message_distribution messages if messages.any?
      problem.fill_host_distribution hosts if hosts.any?
      problem.fill_user_agent_distribution user_agents if user_agents.any?

    end

    def inc_count_in_hash_for(member, hash)
      hash[member] ||= 0
      hash[member] += 1
    end
  end
end