require 'spec_helper'

describe "Callback on Notice" do
  describe "email notifications (configured individually for each app)" do
    custom_thresholds = [2, 4, 8, 16, 32, 64]

    before do
      Errbit::Config.per_app_email_at_notices = true
      @app = Fabricate(:app_with_watcher, :email_at_notices => custom_thresholds)
      @problem = Fabricate(:problem, :app => @app)
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    custom_thresholds.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        allow_any_instance_of(Problem).to receive(:notices_count).and_return(threshold)
        expect(Mailer).to receive(:err_notification).
          and_return(double('email', :deliver => true))
        Fabricate(:notice, :problem => @problem)
      end
    end
  end


  describe "email notifications for a resolved issue" do
    before do
      Errbit::Config.per_app_email_at_notices = true
      @app = Fabricate(:app_with_watcher, :email_at_notices => [1])
      @problem = Fabricate(:problem, :app => @app, :notices_count => 100)
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should send email notification after 1 notice since an error has been resolved" do
      @problem.resolve!
      expect(Mailer).to receive(:err_notification).and_return(double('email', :deliver => true))
      Fabricate(:notice, :problem => @problem)
    end
  end

  describe "should send a notification if a notification service is configured with defaults" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:campfire_notification_service))}
    let(:problem) { Fabricate(:problem, :app => app, :notices_count => 100) }
    let(:backtrace) { Fabricate(:backtrace) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should create a campfire notification" do
      expect_any_instance_of(app.notification_service.class).to receive(:create_notification)

      Notice.create!(:problem => problem, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end
  end

  describe "should not send a notification if a notification service is not configured" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:notification_service))}
    let(:problem) { Fabricate(:problem, :app => app, :notices_count => 100) }
    let(:backtrace) { Fabricate(:backtrace) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should not create a campfire notification" do
      expect_any_instance_of(app.notification_service.class).to_not receive(:create_notification)

      Notice.create!(:problem => problem, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end
  end

  describe 'hipcat notifications' do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:hipchat_notification_service))}
    let(:problem) { Fabricate(:problem, :app => app, :notices_count => 100) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it 'creates a hipchat notification' do
      expect_any_instance_of(app.notification_service.class).to receive(:create_notification)

      Fabricate(:notice, :problem => problem)
    end
  end

  describe "should send a notification at desired intervals" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:campfire_notification_service, :notify_at_notices => [1,2]))}
    let(:backtrace) { Fabricate(:backtrace) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should create a campfire notification on first notice" do
      problem = Fabricate(:problem, :app => app, :notices_count => 1)
      expect_any_instance_of(app.notification_service.class).to receive(:create_notification)

      Notice.create!(:problem => problem, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end

    it "should create a campfire notification on second notice" do
      problem = Fabricate(:problem, :app => app, :notices_count => 1)
      expect_any_instance_of(app.notification_service.class).to receive(:create_notification)

      Notice.create!(:problem => problem, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end

    it "should not create a campfire notification on third notice" do
      problem = Fabricate(:problem, :app => app, :notices_count => 1)
      expect_any_instance_of(app.notification_service.class).to receive(:create_notification)

      Notice.create!(:problem => problem, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end
  end
end
