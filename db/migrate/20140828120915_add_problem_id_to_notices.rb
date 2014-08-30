class AddProblemIdToNotices < ActiveRecord::Migration
  def change
    add_column :notices, :problem_id, :integer
  end
end
