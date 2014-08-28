class FillProblemState < ActiveRecord::Migration
  class Problem < ActiveRecord::Base
  end

  def up
    Problem.where(resolved: true).update_all(state: :resolved)
    Problem.where(resolved: false).update_all(state: :unresolved)
  end

  def down
  end
end
