class AddNoticesCountBeforeUnresolveToProblem < ActiveRecord::Migration
  def change
    add_column :problems, :notices_count_before_unresolve, :integer, default: 0
  end
end
