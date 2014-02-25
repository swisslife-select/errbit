class AfterDeployOperationsWorker
  include Sidekiq::Worker

  def perform(deploy_id)
    deploy = Deploy.find(deploy_id)

    SaveDeployChanges.perform! deploy
  ensure
    DeployNotificationWorker.perform_async(deploy.id)
  end
end
