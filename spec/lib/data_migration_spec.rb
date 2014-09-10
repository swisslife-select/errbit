require 'spec_helper'

describe DataMigration do
  before do
    load File.join(Rails.root, 'spec/fixtures/mongodb_data_for_export.rb')
    @apps = MongodbDataStubs.apps
    @users = MongodbDataStubs.users
    db_name = "test_db"
    db = MongodbDataStubs.db(db_name)
    expect(MongoClient).to receive(:new).and_return(db)
    
    [:apps, :users, :problems, :comments, :errs, :notices, :backtraces].each do |collection|
      records = db[db_name][collection]
      allow(records).to receive(:name).and_return(collection)
      def records.find(*args)
        yield self if block_given?
        self
      end
      allow(records).to receive(:find_one).and_return(records.last)
    end
    
    @migrator = DataMigration::Worker.new({sessions: {default: {database: db_name}}})
    @migrator.prepare
  end
  
  after do
    @migrator.teardown
  end

  describe "migrate users" do
    before do
      @migrator.copy! :users
      @mongo_user = @users.last
      @pg_user = User.last
    end

    it "should copy users" do
      expect(@pg_user).not_to be_nil
    end

    it "should keep track of each user's legacy id" do
      expect(@pg_user.remote_id).to eq(@mongo_user["_id"].to_s)
    end

    User.columns.each do |column|
      it "should correctly copy values for '#{column.name}'" do
        expect(@pg_user.read_attribute(column.name)).to eq(@mongo_user[column.name]) if @mongo_user.has_key?(column.name)
      end
    end
  end

  describe "migrate apps" do
    before do
      @migrator.copy! :users
      @migrator.copy! :apps
      @mongo_app = @apps.last
      @pg_app = App.find_by(api_key: @mongo_app["api_key"])
    end

    it "should copy apps" do
      expect(@pg_app).not_to be_nil
    end

    App.columns.each do |column|
      it "should correct copy value for '#{column.name}'" do
        expect(@pg_app.read_attribute(column.name)).to eq(@mongo_app[column.name]) if @mongo_app.has_key?(column.name)
      end
    end

    it "fill repo_url" do
      github_repo = @mongo_app['github_repo']
      expect(@pg_app.repo_url).to eq("https://github.com/#{github_repo}")
      expect(@pg_app.github_repo).to eq(github_repo)
    end

    it "should copy issue tracker" do
      expect(@pg_app.issue_tracker).not_to be_nil
      expect(@pg_app.issue_tracker.type).to eq(@mongo_app["issue_tracker"]["_type"])
    end

    it "should copy notification service" do
      expect(@pg_app.notification_service).not_to be_nil
      expect(@pg_app.notification_service.type).to eq(@mongo_app["notification_service"]["_type"])
    end

    describe "migrate watchers" do
      it "should copy watchers" do
        expect(@pg_app.watchers.count).to eq(@mongo_app["watchers"].count)
      end

      it "should copy all emails" do
        @mongo_app["watchers"].each do |watcher|
          next unless watcher["email"]
          
          expect(@pg_app.watchers.find_by(email: watcher["email"])).not_to be_nil
        end
      end

      it "should copy all watchers' users" do
        @mongo_app["watchers"].each do |watcher|
          next unless watcher["user_id"]
          
          user = User.find_by remote_id: watcher["user_id"].to_s
          expect(user).not_to be_nil
          expect(@pg_app.watchers.find_by(user_id: user.id)).not_to be_nil
        end
      end

      it 'set watching_errors' do
        all_watch_errors = @pg_app.watchers.pluck(:watching_errors).inject(true) do |memo, item|
          memo && item
        end

        expect(all_watch_errors).to be true
      end

      it 'set watching_deploys' do
        all_watch_deploys = @pg_app.watchers.pluck(:watching_deploys).inject(true) do |memo, item|
          memo && item
        end

        expect(all_watch_deploys).to be true
      end
    end
  end
end
