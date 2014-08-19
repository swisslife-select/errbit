class UpdateProblemNoticesCount < ActiveRecord::Migration
  class Problem < ActiveRecord::Base
  end

  def up
    Problem.where('notices_count IS NULL').update_all(notices_count: 0)

    change_column_null(:problems, :notices_count, false)
    change_column_default(:problems, :notices_count, 0)
  end

  def down
    change_column_null(:problems, :notices_count, true)
    change_column_default(:problems, :notices_count, nil)
  end
end
