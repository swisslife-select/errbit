require 'spec_helper'

describe ProblemUpdaterCache do
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:first_errs) { problem.errs }
  let!(:notice) { Fabricate(:notice, :err => first_errs.first) }

  describe "#update" do
    context "without notice pass args" do
      before do
        problem.update_attribute(:notices_count, 0)
      end

      it 'update the notice_count' do
        expect {
          ProblemUpdaterCache.new(problem).update
        }.to change{
          problem.notices_count
        }.from(0).to(1)
      end

      context "with only one notice" do
        before do
          ProblemUpdaterCache.new(problem).update
        end

        it 'update information about this notice' do
          expect(problem.message).to eq notice.message
          expect(problem.where).to eq notice.where
        end

        it 'update first_notice_at' do
          expect(problem.first_notice_at).to eq notice.reload.created_at
        end

        it 'update last_notice_at' do
          expect(problem.last_notice_at).to eq notice.reload.created_at
        end
      end

      context "with several notices" do
        let!(:notice_2) { Fabricate(:notice, :err => first_errs.first) }
        let!(:notice_3) { Fabricate(:notice, :err => first_errs.first) }
        before do
          ProblemUpdaterCache.new(problem).update
        end
        it 'update information about this notice' do
          expect(problem.message).to eq notice.message
          expect(problem.where).to eq notice.where
        end

        it 'update first_notice_at' do
          expect(problem.first_notice_at.to_i).to be_within(2).of(notice.created_at.to_i)
        end

        it 'update last_notice_at' do
          expect(problem.last_notice_at.to_i).to be_within(1).of(notice.created_at.to_i)
        end

      end
    end

    context "with notice pass in args" do

      before do
        ProblemUpdaterCache.new(problem, notice).update
      end

      it 'increase notices_count by 1' do
        expect {
          ProblemUpdaterCache.new(problem, notice).update
        }.to change{
          problem.notices_count
        }.by(1)
      end

      it 'update information about this notice' do
        expect(problem.message).to eq notice.message
        expect(problem.where).to eq notice.where
      end

      it 'update first_notice_at' do
        expect(problem.first_notice_at).to eq notice.created_at
      end

      it 'update last_notice_at' do
        expect(problem.last_notice_at).to eq notice.created_at
      end
    end
  end
end
