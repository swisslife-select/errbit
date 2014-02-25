class AddNoticeStateToDeploys < ActiveRecord::Migration
  class Deploy < ActiveRecord::Base
  end

  def up
    add_column :deploys, :notice_state, :string

    Deploy.update_all notice_state: 'delivered'
  end

  def down
    remove_column :deploys, :notice_state
  end
end
