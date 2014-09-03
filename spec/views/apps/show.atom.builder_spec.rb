require 'spec_helper'

describe "apps/show.atom.builder", :type => :view do
  let(:app) { stub_model(App, name: 'app') }
  let(:problems) { [
    stub_model(Problem, :message => 'foo', :app => app)
  ]}

  before do
    assign :app, app
    assign :problems, problems
  end

  context "with errs" do
    it 'see the errs message' do
      render
      expect(rendered).to match(problems.first.message)
    end
  end

end
