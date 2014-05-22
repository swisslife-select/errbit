class AddCommentsCountToProblems < ActiveRecord::Migration
  class Problem < ActiveRecord::Base
  end

  def up
    Problem.where('comments_count IS NULL').update_all(comments_count: 0)

    change_column_null(:problems, :comments_count, false)
    change_column_default(:problems, :comments_count, 0)
  end

  def down
    change_column_null(:problems, :comments_count, true)
    change_column_default(:problems, :comments_count, nil)
  end
end
