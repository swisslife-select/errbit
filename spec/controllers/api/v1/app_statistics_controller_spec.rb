require 'spec_helper'

describe Api::V1::AppStatisticsController do
  render_views

  let(:user) { Fabricate(:user) }
  let!(:watcher) { Fabricate(:user_watcher, app: app, user: user) }
  let(:app) { Fabricate(:app) }


  describe "GET /app_statistics/:id" do
    it "successfully" do
      get :show, id: app.id, format: :json, User.token_authentication_key => user.authentication_token
      expect(response).to be_success
    end
  end
end
