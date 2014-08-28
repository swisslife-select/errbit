class DeployObserver < ActiveRecord::Observer
  def after_create(deploy)
    deploy.execute_after_commit do
      AfterDeployOperationsWorker.perform_async(deploy.id)
    end
  end
end
