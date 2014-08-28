class RemoveResolvedFromProblems < ActiveRecord::Migration
  def up
    remove_column :problems, :resolved
  end

  def down
    add_column :problems, :resolved, :boolean
  end
end
