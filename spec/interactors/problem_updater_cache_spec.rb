require 'spec_helper'

describe ProblemUpdaterCache do
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:first_errs) { problem.errs }
  let!(:notice) { Fabricate(:notice, :err => first_errs.first) }

  describe "#update" do
    context "with notice pass in args" do

      before do
        ProblemUpdaterCache.new(problem, notice).update
      end

      it 'update information about this notice' do
        expect(problem.message).to eq notice.message
        expect(problem.where).to eq notice.where
      end

      it 'update last_notice_at' do
        expect(problem.last_notice_at).to eq notice.created_at
      end
    end
  end
end
