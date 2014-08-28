class AddStateForProblem < ActiveRecord::Migration
  def change
    add_column :problems, :state, :string
  end
end
