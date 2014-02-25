class DeployNotificationWorker
  include Sidekiq::Worker

  def perform(deploy_id)
    deploy = Deploy.find(deploy_id)
    return unless deploy.should_notify?

    Mailer.deploy_notification(deploy).deliver
    deploy.mark_as_delivered_notice
  end
end
