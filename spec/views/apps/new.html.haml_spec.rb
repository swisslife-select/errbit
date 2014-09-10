require 'spec_helper'

describe "apps/new.html.haml", :type => :view do
  let(:app) { stub_model(App, name: 'app') }
  before do
    assign :app, app
    allow(controller).to receive(:current_user) { stub_model(User) }
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'cancel' link" do
      render

      expect(action_bar).to have_selector('a.button', :text => 'cancel')
    end

  end

  context "with unvalid app" do
    before do
      app.errors.add(:base,'You must specify your')
    end

    it 'see the error' do
      render
      expect(rendered).to match(/You must specify your/)
    end
  end

end

