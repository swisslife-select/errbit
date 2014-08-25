require 'spec_helper'

describe Problem do

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

    context "Fabricate(:problem_with_errs)" do
      it 'should have 3 errs' do
        expect{
          Fabricate(:problem_with_errs)
        }.to change(Err, :count).by(3)
      end
    end
  end

  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      err = Fabricate(:err)
      problem = err.problem
      expect(problem).to_not be_nil

      notice1 = Fabricate(:notice, :err => err)
      expect(problem.last_notice_at).to be_within(1).of(notice1.created_at)

      notice2 = Fabricate(:notice, :err => err)
      expect(problem.last_notice_at).to be_within(1).of(notice2.created_at)
    end
  end

  context '#first_notice_at' do
    it "returns the created_at timestamp of the first notice" do
      err = Fabricate(:err)
      problem = err.problem
      expect(problem).to_not be_nil

      notice1 = Fabricate(:notice, :err => err)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)

      notice2 = Fabricate(:notice, :err => err)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)
    end
  end

  context '#message' do
    it "adding a notice caches its message" do
      err = Fabricate(:err)
      problem = err.problem
      expect {
        Fabricate(:notice, :err => err, :message => 'ERR 1')
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

  context "#resolved?" do
    it "should start out as unresolved" do
      problem = Problem.new
      expect(problem).to_not be_resolved
      expect(problem).to be_unresolved
    end

    it "should be able to be resolved" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.resolve!
      expect(problem.reload).to be_resolved
    end
  end

  context "resolve!" do
    it "marks the problem as resolved" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.resolve!
      expect(problem).to be_resolved
    end

    it "should record the time when it was resolved" do
      problem = Fabricate(:problem)
      expected_resolved_at = Time.zone.now
      Timecop.freeze(expected_resolved_at) do
        problem.resolve!
      end
      expect(problem.resolved_at.to_s).to eq expected_resolved_at.to_s
    end

    it "should not reset notice count" do
      problem = Fabricate(:problem, :notices_count => 1)
      original_notices_count = problem.notices_count
      expect(original_notices_count).to be > 0

      problem.resolve!
      expect(problem.notices_count).to eq original_notices_count
    end

    it "should throw an err if it's not successful" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.stub(:valid?).and_return(false)
      ## update_attributes not test #valid? but #errors.any?
      # https://github.com/mongoid/mongoid/blob/master/lib/mongoid/persistence.rb#L137
      er = ActiveModel::Errors.new(problem)
      er.add_on_blank(:resolved)
      problem.stub(:errors).and_return(er)
      expect(problem).to_not be_valid
      expect {
        problem.resolve!
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "#unmerge!" do
    it "creates a separate problem for each err" do
      problem1 = Fabricate(:notice).problem
      problem2 = Fabricate(:notice).problem
      merged_problem = Problem.merge!(problem1, problem2)
      expect(merged_problem.errs.length).to eq 2

      expect { merged_problem.unmerge! }.to change(Problem, :count).by(1)
      expect(merged_problem.errs(true).length).to eq 1
    end

    it "runs smoothly for problem without errs" do
      expect { Fabricate(:problem).unmerge! }.not_to raise_error
    end
  end

  context "Scopes" do
    context "resolved" do
      it 'only finds resolved Problems' do
        resolved = Fabricate(:problem, :resolved => true)
        unresolved = Fabricate(:problem, :resolved => false)
        expect(Problem.resolved).to include(resolved)
        expect(Problem.resolved).to_not include(unresolved)
      end
    end

    context "unresolved" do
      it 'only finds unresolved Problems' do
        resolved = Fabricate(:problem, :resolved => true)
        unresolved = Fabricate(:problem, :resolved => false)
        expect(Problem.unresolved).to_not include(resolved)
        expect(Problem.unresolved).to include(unresolved)
      end
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
      @err = Fabricate(:err, :problem => @problem)
      notice = Fabricate(:notice, :err => @err)
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
      Fabricate(:notice, :err => @err)
      expect(@app.reload.unresolved_problems_count).to eq 1
    end

    it "increasing count after adding new error to resolved problem" do
      @problem.resolve!
      err = Fabricate(:err, :problem => @problem)
      Fabricate(:notice, :err => err)
      expect(@app.reload.unresolved_problems_count).to eq 1
    end
  end

  context "distributions" do
    before do
      @problem = Fabricate(:problem)
      @err = Fabricate(:err, problem: @problem)
      @notice1 = Fabricate(:notice, message: "mistake", err: @err)
      @notice2 = Fabricate(:notice, message: "error", err: @err)
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

