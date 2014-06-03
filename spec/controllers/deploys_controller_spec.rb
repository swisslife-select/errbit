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

end

