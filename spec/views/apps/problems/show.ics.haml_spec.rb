require 'spec_helper'

describe "apps/problems/show.html.ics" do
  let(:problem) { Fabricate(:problem) }
  before do
    view.stub(:problem).and_return(problem)
  end

  it 'should work' do
    render :template => 'apps/problems/show', :formats => [:ics], :handlers => [:haml]
  end


end
