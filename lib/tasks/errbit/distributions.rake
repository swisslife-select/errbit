namespace :errbit do
  desc "Fill problems distributions(messages, hosts, user_agents) from db to redis"
  task fill_problem_distributions: :environment do
    DistributionFiller.perform
  end

end
