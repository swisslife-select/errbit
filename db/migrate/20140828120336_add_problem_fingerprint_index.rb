class AddProblemFingerprintIndex < ActiveRecord::Migration
  def change
    add_index :problems, [:app_id, :fingerprint]
  end
end
