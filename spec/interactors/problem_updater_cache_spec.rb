require 'spec_helper'

describe ProblemUpdaterCache do
  let(:problem) { Fabricate(:problem) }
  let!(:notice) { Fabricate(:notice, :problem => problem) }

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
