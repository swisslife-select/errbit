class AfterDeployOperationsWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  sidekiq_retry_in do |count|
    # 1, 8, 27
    1.hour * (count + 1)**3
  end

  def perform(deploy_id)
    deploy = Deploy.find(deploy_id)

    SaveDeployChanges.perform! deploy
  ensure
    DeployNotificationWorker.perform_async(deploy.id)
  end
end
