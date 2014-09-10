require 'spec_helper'

describe "apps/index.html.haml", :type => :view do
  before do
    deploy = Fabricate(:deploy, :created_at => Time.now, :revision => "123456789abcdef")
    app = Fabricate(:app, :deploys => [deploy])
    assign :apps, [app]
    assign :q , App.search
    allow(controller).to receive(:current_user) { stub_model(User) }
  end

  describe "deploy column" do
    it "should show the first 7 characters of the revision in parentheses" do
      render
      expect(rendered).to match(/\(1234567\)/)
    end
  end
end

