class RemoveAppNameFromProblems < ActiveRecord::Migration
  class App < ActiveRecord::Base
    has_many :problems
  end

  class Problem < ActiveRecord::Base
    belongs_to :app
  end

  def up
    remove_column :problems, :app_name
  end

  def down
    add_column :problems, :app_name, :string
    add_index :problems, :app_name

    App.find_each do |app|
      app.problems.update_all app_name: app.name
    end
  end
end
