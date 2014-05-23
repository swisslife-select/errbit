class DeployObserver < ActiveRecord::Observer
  observe :deploy

  def after_commit(object)
    after_commit_on_create(object) if object.send(:transaction_include_any_action?, [:create])
  end

  def after_commit_on_create(deploy)
    AfterDeployOperationsWorker.perform_async(deploy.id)
  end
end
