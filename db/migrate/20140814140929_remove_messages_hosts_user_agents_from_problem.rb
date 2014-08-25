class RemoveMessagesHostsUserAgentsFromProblem < ActiveRecord::Migration
  def up
    remove_columns :problems, :messages, :hosts, :user_agents
  end

  def down
    add_column :problems, :messages, :text
    add_column :problems, :hosts, :text
    add_column :problems, :user_agents, :text
  end
end
