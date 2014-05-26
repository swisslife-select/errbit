require 'spec_helper'

describe DeploysController do
  render_views

  context 'POST #create' do
    before do
      @params = {
        'local_username' => 'john.doe',
        'scm_repository' => 'git@github.com/errbit/errbit.git',
        'rails_env'      => 'production',
        'scm_revision'   => '19d77837eef37902cf5df7e4445c85f392a8d0d5',
        'message'        => 'johns first deploy'
      }
      @app = Fabricate(:app_with_watcher, :notify_on_deploys => true, :api_key => 'APIKEY')
    end

    it 'finds the app via the api key' do
      expect(App).to receive(:find_by!).with(api_key: 'APIKEY').and_return(@app)
      post :create, :deploy => @params, :api_key => 'APIKEY'
    end

    it 'creates a deploy' do
      App.stub(:find_by!).and_return(@app)
      expect(@app.deploys).to receive(:create!).
        with({
          :username     => 'john.doe',
          :environment  => 'production',
          :repository   => 'git@github.com/errbit/errbit.git',
          :revision     => '19d77837eef37902cf5df7e4445c85f392a8d0d5',
          :message      => 'johns first deploy'

        }).and_return(Fabricate(:deploy))
      post :create, :deploy => @params, :api_key => 'APIKEY'
    end

    it 'sends an email notification when configured to do so' do
      post :create, :deploy => @params, :api_key => 'APIKEY'
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(@app.watchers.first.email)
      expect(email.subject).to eq "[#{@app.name}] Deployed to production by john.doe"
    end

  end

  context "GET #index" do
    before(:each) do
      @deploy = Fabricate :deploy
      sign_in Fabricate(:admin)
      get :index, :app_id => @deploy.app.id
    end

    it "should render successfully" do
      expect(response).to be_success
    end

    it "should contain info about existing deploy" do
      expect(response.body).to match(@deploy.short_revision)
      expect(response.body).to match(@deploy.app.name)
    end
  end

  context "GET #index in atom format" do
    before(:each) do
      @deploy = Fabricate :deploy
      watcher = Fabricate :user_watcher, app: @deploy.app

      get :index, app_id: @deploy.app.id, format: :atom, auth_token: watcher.user.authentication_token
    end

    it "should render successfully" do
      expect(response).to be_success
    end
  end

  context "GET #show" do
    before(:each) do
      @deploy = Fabricate :deploy
      @params = { app_id: @deploy.app.id, id: @deploy.id }

      watcher = Fabricate :user_watcher, app: @deploy.app
      sign_in watcher.user
    end

    it "should render successfully" do
      get :show, @params
      response.should be_success
    end
  end

end

