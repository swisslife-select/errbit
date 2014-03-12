module SaveDeployChanges
  class << self
    def perform!(deploy)
      return if deploy.vcs_changes.any?
      prev_deploy = deploy.previous
      return unless prev_deploy

      curr_commit = deploy.revision
      prev_commit = prev_deploy.revision

      return if curr_commit.blank?
      return if prev_commit.blank?

      repo_name = "repo-#{deploy.app_id}-#{deploy.created_at.to_i}"
      repository_addr = deploy.repository

      changes = differ.diff(repo_name, repository_addr, prev_commit, curr_commit)

      deploy.vcs_changes = changes
      deploy.save!
    end

    def differ
      ServiceLocator.differ
    end
  end
end
