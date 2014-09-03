require 'spec_helper'

describe Apps::DeploysController, :type => :controller do
  render_views

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

      get :index, app_id: @deploy.app_id, format: :atom, auth_token: watcher.user.authentication_token
    end

    it "should render successfully" do
      expect(response).to be_success
    end
  end

  context "GET #show" do
    before(:each) do
      @deploy = Fabricate :deploy
      @params = { app_id: @deploy.app_id, id: @deploy.id }

      watcher = Fabricate :user_watcher, app: @deploy.app
      sign_in watcher.user
    end

    it "should render successfully" do
      get :show, @params
      expect(response).to be_success
    end
  end

end

