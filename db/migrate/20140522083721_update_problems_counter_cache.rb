class UpdateProblemsCounterCache < ActiveRecord::Migration
  class Problem < ActiveRecord::Base
    belongs_to :app, inverse_of: :problems
    counter_culture :app, column_names: { ["problems.resolved = ?", false] => 'unresolved_problems_count' }
  end

  class App < ActiveRecord::Base
    has_many :problems
  end

  def up
    Problem.counter_culture_fix_counts
  end

  def down
  end
end
