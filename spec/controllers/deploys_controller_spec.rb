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
      @app = Fabricate(:app_with_watcher)
    end

    it 'creates a deploy' do
      post :create, deploy: @params, api_key: @app.api_key
      expect(response).to be_success
      expect(@app.deploys.one?).to be true
    end
  end

end

