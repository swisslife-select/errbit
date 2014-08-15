module DistributionFiller
  SAMPLE_SIZE = 100

  # Algorithm uses a samples, so problems having several errs will have inaccurate distribution.

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
        notices = err.notices.limit(SAMPLE_SIZE)
        notices.each do |n|
          inc_count_in_hash_for(n.message_signature, messages)
          inc_count_in_hash_for(n.host, hosts)
          inc_count_in_hash_for(n.user_agent_string, user_agents)
        end
      end

      fill_distribution(problem, :message, messages)
      fill_distribution(problem, :host, hosts)
      fill_distribution(problem, :user_agent, user_agents)
    end

    def fill_distribution(problem, distribution_name, sample)
      problem.send "clear_#{distribution_name}_distribution"
      return if sample.empty?

      normalized_sample = normalize_sample(sample, problem.notices_count)
      problem.send "fill_#{distribution_name}_distribution", normalized_sample
    end

    # total count messages in distribution must equal real_total_count
    def normalize_sample(sample_hash, real_total_count)
      total_count = sample_hash.values.sum
      coefficient = real_total_count.to_f / total_count
      sample_hash.each_with_object({}){ |(k,v), h| h[k] = coefficient * v  }
    end

    def inc_count_in_hash_for(member, hash)
      hash[member] ||= 0
      hash[member] += 1
    end
  end
end
