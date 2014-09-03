require 'spec_helper'

describe Problem, :type => :model do

  context 'validations' do
    it 'requires an environment' do
      problem = Fabricate.build(:problem, :environment => nil)
      expect(problem).to_not be_valid
      expect(problem.errors[:environment]).to include("can't be blank")
    end
  end

  describe "Fabrication" do
    context "Fabricate(:problem)" do
      it 'should have no comment' do
        expect{
          Fabricate(:problem)
        }.to_not change(Comment, :count)
      end
    end

    context "Fabricate(:problem_with_comments)" do
      it 'should have 3 comments' do
        expect{
          Fabricate(:problem_with_comments)
        }.to change(Comment, :count).by(3)
      end
    end
  end

  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      problem = Fabricate(:problem)
      notice1 = Fabricate(:notice, :problem => problem)
      expect(problem.last_notice_at).to be_within(1).of(notice1.created_at)

      notice2 = Fabricate(:notice, :problem => problem)
      expect(problem.last_notice_at).to be_within(1).of(notice2.created_at)
    end
  end

  context '#first_notice_at' do
    it "returns the created_at timestamp of the first notice" do
      problem = Fabricate(:problem)

      notice1 = Fabricate(:notice, :problem => problem)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)

      notice2 = Fabricate(:notice, :problem => problem)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)
    end
  end

  context '#message' do
    it "adding a notice caches its message" do
      problem = Fabricate(:problem)
      expect {
        Fabricate(:notice, :problem => problem, :message => 'ERR 1')
      }.to change(problem, :message).from(nil).to('ERR 1')
    end
  end

  context 'being created' do
    context 'when the app has err notifications set to false' do
      it 'should not send an email notification' do
        app = Fabricate(:app_with_watcher, :notify_on_errs => false)
        expect(Mailer).to_not receive(:err_notification)
        Fabricate(:problem, :app => app)
      end
    end
  end

  context "resolve" do
    it "should record the time when it was resolved" do
      problem = Fabricate(:problem)
      expected_resolved_at = Time.current
      Timecop.freeze(expected_resolved_at) do
        problem.resolve!
      end
      expect(problem.resolved_at).to eq expected_resolved_at
    end
  end

  context "unresolve" do
    it "should record notices_count when it was unresolved" do
      problem = Fabricate(:problem_resolved, notices_count: 100)
      notices_count = problem.notices_count
      problem.unresolve!
      expect(problem.notices_count_before_unresolve).to eq notices_count
    end
  end

  context "#last_deploy_at" do
    before do
      @app = Fabricate(:app)
      @last_deploy = Time.at(10.days.ago.localtime.to_i)
      deploy = Fabricate(:deploy, :app => @app, :created_at => @last_deploy, :environment => "production")
    end

    it "is set when a problem is created" do
      problem = Fabricate(:problem, :app => @app, :environment => "production")
      assert_equal @last_deploy, problem.last_deploy_at
    end

    it "is updated when a deploy is created" do
      problem = Fabricate(:problem, :app => @app, :environment => "production")
      next_deploy = Time.at(5.minutes.ago.localtime.to_i)
      expect {
        @deploy = Fabricate(:deploy, :app => @app, :created_at => next_deploy)
        problem.reload
      }.to change(problem, :last_deploy_at).from(@last_deploy).to(next_deploy)
    end
  end

  context "app unresolved_problems_count cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      notice = Fabricate(:notice, :problem => @problem)
    end

    it "setting count to 1 when adding first problem" do
      expect(@app.reload.unresolved_problems_count).to eq 1
    end

    it "setting count to 0 when all problems are resolved" do
      @problem.resolve!
      expect(@app.reload.unresolved_problems_count).to eq 0
    end

    it "increasing count after adding notice to existing error for resolved problem" do
      @problem.resolve!
      Fabricate(:notice, :problem => @problem)
      expect(@app.reload.unresolved_problems_count).to eq 1
    end

    it "increasing count after adding new error to resolved problem" do
      @problem.resolve!
      Fabricate(:notice, :problem => @problem)
      expect(@app.reload.unresolved_problems_count).to eq 1
    end
  end

  context "distributions" do
    before do
      @problem = Fabricate(:problem)
      @notice1 = Fabricate(:notice, message: "mistake", problem: @problem)
      @notice2 = Fabricate(:notice, message: "error", problem: @problem)
    end

    it "correct" do
      messages = @problem.message_distribution.map(&:first)
      percents = @problem.message_distribution.map(&:last)

      expect(@problem.message_distribution.length).to be(2)
      expect(messages).to include(@notice1.message_signature, @notice2.message_signature)
      expect(percents.sum).to be(100.0)
    end

    it "remove redis key after problem destroy" do
      @problem.destroy
      expect(@problem.message_distribution.none?).to be(true)
    end
  end
end

