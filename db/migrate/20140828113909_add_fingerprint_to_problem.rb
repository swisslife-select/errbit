class AddFingerprintToProblem < ActiveRecord::Migration
  def change
    add_column :problems, :fingerprint, :string
  end
end
