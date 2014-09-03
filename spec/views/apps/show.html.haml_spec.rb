require 'spec_helper'

describe "apps/show.html.haml", :type => :view do
  let(:app) { stub_model(App, name: 'app') }
  let(:user) { stub_model(User) }

  let(:action_bar) do
    view.content_for(:action_bar)
  end

  before do
    assign :app, app
    allow(controller).to receive(:current_user) { user }
  end

  context "without errs" do
    it 'see no errs' do
      render
      expect(rendered).to match(/No errs have been/)
    end
  end

  context "with user watch application" do
    before do
      allow(user).to receive(:watching?).with(app).and_return(true)
    end
    it 'see the unwatch button' do
      render
      expect(action_bar).to include(I18n.t('apps.show.unwatch'))
    end
  end

  context "with user not watch application" do
    before do
      allow(user).to receive(:watching?).with(app).and_return(false)
    end
    it 'not see the unwatch button' do
      render
      content = action_bar || ''
      expect(content).to_not include(I18n.t('apps.show.unwatch'))
    end
  end

end

