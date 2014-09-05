class RemoveErrIdFromNotices < ActiveRecord::Migration
  def up
    remove_column :notices, :err_id
  end

  def down
  end
end
