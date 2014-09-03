require 'spec_helper'

describe "problems/index.html.haml", :type => :view do
  let!(:problem_1) { Fabricate(:problem) }
  let!(:problem_2) { Fabricate(:problem, :app => problem_1.app) }

  before do
    # view.stub(:app).and_return(problem.app)
    allow(view).to receive(:selected_problems).and_return([])
    allow(controller).to receive(:current_user) { Fabricate(:user) }
    assign :problems, Kaminari.paginate_array([problem_1, problem_2]).page(1).per(10)
    assign :q, Problem.search
  end

  describe "with problem" do
    it 'should works' do
      render
      expect(rendered).to have_selector('div#problem_table.problem_table')
    end
  end

end

