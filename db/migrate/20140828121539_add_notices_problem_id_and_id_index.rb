class AddNoticesProblemIdAndIdIndex < ActiveRecord::Migration
  def change
    add_index :notices, [:problem_id, :id]
  end
end
