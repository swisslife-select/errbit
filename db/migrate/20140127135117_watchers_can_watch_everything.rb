class WatchersCanWatchEverything < ActiveRecord::Migration
  class Watcher < ActiveRecord::Base
  end

  def up
    Watcher.update_all watching_errors: true, watching_deploys: true
  end

  def down
  end
end
