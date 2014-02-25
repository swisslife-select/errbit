class DeployObserver < ActiveRecord::Observer
  observe :deploy

  def after_commit(object)
    after_commit_on_create(object) if object.send(:transaction_include_action?, :create)
  end

  def after_commit_on_create(deploy)
    Mailer.deploy_notification(deploy).deliver if deploy.should_notify?
  end
end
