module SaveDeployChanges
  class << self
    def perform!(deploy)
      return if deploy.vcs_changes.any?
      prev_deploy = deploy.previous
      return unless prev_deploy

      repo_name = "repo-#{deploy.app_id}-#{deploy.created_at.to_i}"
      repository_addr = deploy.repository

      prev_commit = prev_deploy.revision
      curr_commit = deploy.revision

      changes = differ.diff(repo_name, repository_addr, prev_commit, curr_commit)

      deploy.vcs_changes = changes
      deploy.save!
    end

    def differ
      ServiceLocator.differ
    end
  end
end
