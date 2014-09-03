require 'spec_helper'

describe DataMigration do
  before do
    load File.join(Rails.root, 'spec/fixtures/mongodb_data_for_export.rb')
    @apps = MongodbDataStubs.apps
    @users = MongodbDataStubs.users
    db_name = "test_db"
    db = MongodbDataStubs.db(db_name)
    MongoClient.should_receive(:new).and_return(db)
    
    [:apps, :users, :problems, :comments, :errs, :notices, :backtraces].each do |collection|
      records = db[db_name][collection]
      records.stub(:name).and_return(collection)
      def records.find(*args)
        yield self if block_given?
        self
      end
      records.stub(:find_one).and_return(records.last)
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
      @pg_user.should_not be_nil
    end

    it "should keep track of each user's legacy id" do
      @pg_user.remote_id.should == @mongo_user["_id"].to_s
    end

    User.columns.each do |column|
      it "should correctly copy values for '#{column.name}'" do
        @pg_user.read_attribute(column.name).should == @mongo_user[column.name] if @mongo_user.has_key?(column.name)
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
      @pg_app.should_not be_nil
    end

    App.columns.each do |column|
      it "should correct copy value for '#{column.name}'" do
        @pg_app.read_attribute(column.name).should == @mongo_app[column.name] if @mongo_app.has_key?(column.name)
      end
    end

    it "fill repo_url" do
      github_repo = @mongo_app['github_repo']
      @pg_app.repo_url.should == "https://github.com/#{github_repo}"
      @pg_app.github_repo.should == github_repo
    end

    it "should copy issue tracker" do
      @pg_app.issue_tracker.should_not be_nil
      @pg_app.issue_tracker.type.should == @mongo_app["issue_tracker"]["_type"]
    end

    it "should copy notification service" do
      @pg_app.notification_service.should_not be_nil
      @pg_app.notification_service.type.should == @mongo_app["notification_service"]["_type"]
    end

    describe "migrate watchers" do
      it "should copy watchers" do
        @pg_app.watchers.count.should == @mongo_app["watchers"].count
      end

      it "should copy all emails" do
        @mongo_app["watchers"].each do |watcher|
          next unless watcher["email"]
          
          @pg_app.watchers.find_by(email: watcher["email"]).should_not be_nil
        end
      end

      it "should copy all watchers' users" do
        @mongo_app["watchers"].each do |watcher|
          next unless watcher["user_id"]
          
          user = User.find_by remote_id: watcher["user_id"].to_s
          user.should_not be_nil
          @pg_app.watchers.find_by(user_id: user.id).should_not be_nil
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
