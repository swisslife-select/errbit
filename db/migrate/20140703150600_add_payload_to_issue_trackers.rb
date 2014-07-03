class AddPayloadToIssueTrackers < ActiveRecord::Migration
  def change
    add_column :issue_trackers, :payload, :text
  end
end
