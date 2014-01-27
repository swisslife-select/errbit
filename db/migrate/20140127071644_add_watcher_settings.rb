class AddWatcherSettings < ActiveRecord::Migration
  def up
    add_column :watchers, :watching_errors, :boolean
    add_column :watchers, :watching_deploys, :boolean
  end

  def down
    remove_column :watchers, :watching_errors
    remove_column :watchers, :watching_deploys
  end
end
