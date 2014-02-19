class RemoveGithubAndBitbucketRepo < ActiveRecord::Migration
  def up
    remove_column :apps, :github_repo
    remove_column :apps, :bitbucket_repo
  end

  def down
    add_column :apps, :github_repo, :string
    add_column :apps, :bitbucket_repo, :string
  end
end
