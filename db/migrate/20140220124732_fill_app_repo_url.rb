class FillAppRepoUrl < ActiveRecord::Migration
  class App < ActiveRecord::Base
  end

  def up
    App.find_each do |app|
      github = "https://github.com/#{app.github_repo}" if app.github_repo?
      bitbucket = "https://bitbucket.com/#{app.bitbucket_repo}" if app.bitbucket_repo?
      app.repo_url = github || bitbucket
      app.save!
    end
  end

  def down
  end
end
