require 'spec_helper'

class TestsController < ActionController::Base
  def show
    raise 'test error'
  end
end

describe "Self exceptions handling" do
  before do
    Rails.application.routes.draw { resource :test }

    Airbrake::Configuration.any_instance.stub(:public?).and_return(true)
  end

  after do
    Rails.application.reload_routes!
  end

  it "work" do
    expect { get '/test' }.to raise_error

    app = App.find_by name: "Self.Errbit"
    expect(app.problems.count).to be(1)

    problem = app.problems.last
    expect(problem.message).to eq('RuntimeError: test error')
  end
end
