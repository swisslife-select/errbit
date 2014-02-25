class AddChangesToDeploy < ActiveRecord::Migration
  def change
    add_column :deploys, :vcs_changes, :text
  end
end
