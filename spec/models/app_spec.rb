require 'spec_helper'

describe App do

  context 'being created' do
    it 'generates a new api-key' do
      app = Fabricate.build(:app)
      expect(app.api_key).to be_nil
      app.save
      expect(app.api_key).to_not be_nil
    end

    it 'generates a correct api-key' do
      app = Fabricate(:app)
      expect(app.api_key).to match(/^[a-f0-9]{32}$/)
    end

    it 'is fine with blank github repos' do
      app = Fabricate.build(:app, :repo_url => "")
      app.save
      expect(app.github_repo).to be_blank
    end

    it 'removes domain from https github repos' do
      app = Fabricate.build(:app, :repo_url => "https://github.com/errbit/errbit")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end

    it 'normalizes public git repo as a github repo' do
      app = Fabricate.build(:app, :repo_url => "https://github.com/errbit/errbit.git")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end

    it 'normalizes private git repo as a github repo' do
      app = Fabricate.build(:app, :repo_url => "git@github.com:errbit/errbit.git")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end
  end

  context '#github_repo?' do
    it 'is true when there is a github_repo' do
      app = Fabricate(:app, :repo_url => "https://github.com/errbit/errbit.git")
      expect(app.github_repo?).to be_true
    end

    it 'is false when no github_repo' do
      app = Fabricate(:app)
      expect(app.github_repo?).to be_false
    end

    it 'is false when app has another repo' do
      app = Fabricate(:app, :repo_url => "https://bitbucket.com/errbit/errbit.git")
      app.github_repo?.should be_false
    end
  end

  context "application_wide_recipients" do
    it "should send notices to all users plus all app watchers" do
      @app = Fabricate(:app)
      Fabricate(:user)
      Fabricate(:watcher, :app => @app)

      @app.reload
      @app.notify_all_users = true

      expected_count = User.count + @app.watchers.count
      expect(@app.error_recipients.count).to eq(expected_count)
    end
  end

  context "error_recipients" do
    it "should send notices to the configured watchers" do
      @app = Fabricate(:app)
      Fabricate(:watcher, :app => @app)
      Fabricate(:watcher_of_errors, :app => @app)
      Fabricate(:watcher_of_deploys, :app => @app)
      @app.reload
      @app.notify_all_users = false
      @app.error_recipients.count.should == 2
    end
  end

  context "deploy_recipients" do
    it "should send notices to the configured watchers" do
      @app = Fabricate(:app)
      Fabricate(:watcher, :app => @app)
      Fabricate(:watcher_of_errors, :app => @app)
      Fabricate(:watcher_of_deploys, :app => @app)
      @app.reload
      @app.notify_all_users = false
      @app.deploy_recipients.count.should == 2
    end
  end

  context "emailable?" do
    it "should be true if notify on errs and there are notification recipients" do
      app = Fabricate(:app, :notify_on_errs => true, :notify_all_users => false)
      2.times { app.watchers.create Fabricate.attributes_for(:watcher) }
      expect(app.emailable?).to be_true
    end

    it "should be false if notify on errs is disabled" do
      app = Fabricate(:app, :notify_on_errs => false, :notify_all_users => false)
      2.times { app.watchers.create Fabricate.attributes_for(:watcher) }
      expect(app.emailable?).to be_false
    end

    it "should be false if there are no notification recipients" do
      app = Fabricate(:app, :notify_on_errs => true, :notify_all_users => false)
      expect(app.watchers).to be_empty
      expect(app.emailable?).to be_false
    end
  end

  context '#find_or_create_err!' do
    let(:app) { Fabricate(:app) }
    let(:conditions) { {
        :error_class  => 'Whoops',
        :environment  => 'production',
        :fingerprint  => 'some-finger-print'
      }
    }

    it 'returns the correct err if one already exists' do
      existing = Fabricate(:err, {
        :problem => Fabricate(:problem, :app => app),
        :fingerprint => conditions[:fingerprint]
      })
      expect(Err.where(conditions.slice(:fingerprint)).first).to eq existing
      expect(app.find_or_create_err!(conditions)).to eq existing
    end

    it 'assigns the returned err to the given app' do
      expect(app.find_or_create_err!(conditions).app).to eq app
    end

    it 'creates a new problem if a matching one does not already exist' do
      expect(Err.where(conditions.slice(:fingerprint)).first).to be_nil
      expect {
        app.find_or_create_err!(conditions)
      }.to change(Problem,:count).by(1)
    end

    context "without error_class" do
      let(:conditions) { {
        :environment  => 'production',
        :fingerprint  => 'some-finger-print'
      }
      }
      it 'save the err' do
        expect(Err.where(conditions.slice(:fingerprint)).first).to be_nil
        expect {
          app.find_or_create_err!(conditions)
        }.to change(Problem,:count).by(1)
      end
    end
  end
end

