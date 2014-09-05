class RemoveErrs < ActiveRecord::Migration
  def up
    drop_table :errs
  end

  def down
  end
end
