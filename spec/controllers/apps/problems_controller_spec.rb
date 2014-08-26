require 'spec_helper'

describe Apps::ProblemsController do
  let(:app) { Fabricate(:app) }
  let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :environment => "production")) }

  describe "GET /apps/:app_id/problems/:id" do
    #render_views

    context 'when logged in as an admin' do
      before do
        sign_in Fabricate(:admin)
      end

      it "finds the problem" do
        get :show, :app_id => app.id, :id => err.problem.id
        expect(assigns(:problem)).to eq err.problem
      end

      it "successfully render page" do
        get :show, :app_id => app.id, :id => err.problem.id
        expect(response).to be_success
      end

      context 'pagination' do
        let!(:notices) do
          3.times.reduce([]) do |coll, i|
            coll << Fabricate(:notice, :err => err, :created_at => (Time.now + i))
          end
        end

        it "paginates the notices 1 at a time, starting with the most recent" do
          get :show, :app_id => app.id, :id => err.problem.id
          expect(assigns(:notice)).to eq(notices.last)
        end

        it "paginates the notices 1 at a time, based on then notice_id param" do
          get :show, :app_id => app.id, :id => err.problem.id, :notice_id => notices.first
          expect(assigns(:notice)).to eq(notices.first)
        end
      end

    end

    context 'when logged in as a user' do
      before do
        sign_in(@user = Fabricate(:user))
        @unwatched_err = Fabricate(:err)
        @watched_app = Fabricate(:app)
        @watcher = Fabricate(:user_watcher, :user => @user, :app => @watched_app)
        @watched_err = Fabricate(:err, :problem => Fabricate(:problem, :app => @watched_app))
      end

      it 'finds the problem if the user is watching the app' do
        get :show, :app_id => @watched_app.to_param, :id => @watched_err.problem.id
        expect(assigns(:problem)).to eq @watched_err.problem
      end

      it 'redirect to root path if the user is not watching the app' do
        get :show, :app_id => @unwatched_err.problem.app_id, :id => @unwatched_err.problem.id
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when logged out' do
      before do
        sign_out :user
      end

      it "redirect to session path" do
        get :show, app_id: app.id, id: err.problem.id
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "patch/apps/:app_id/problems/:id/resolve" do
    before do
      sign_in Fabricate(:admin)

      @err = Fabricate(:err)
      @err.app.problems.stub(:detect_by_param!).and_return(@err.problem)
      @err.problem.stub(:resolve!)
    end

    it "should resolve the issue" do
      patch :resolve, :app_id => @err.app.id, :id => @err.problem.id
      @err.reload
      expect(@err.problem.resolved?).to be true
    end

    it "should redirect to the app page" do
      patch :resolve, :app_id => @err.app.id, :id => @err.problem.id
      expect(response).to redirect_to(app_path(@err.app))
    end

    it "should redirect back to problems page" do
      request.env["HTTP_REFERER"] = problems_path
      patch :resolve, :app_id => @err.app.id, :id => @err.problem.id
      expect(response).to redirect_to(problems_path)
    end

    context 'when logged out' do
      before do
        sign_out :user
      end

      it 'should redirect' do
        patch :resolve,  :app_id => @err.app.id, :id => @err.problem.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /apps/:app_id/problems/:id/create_issue" do
    #render_views

    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "successful issue creation" do
      context "lighthouseapp tracker" do
        let(:notice) { Fabricate :notice }
        let(:tracker) { Fabricate :lighthouse_tracker, :app => notice.app }
        let(:problem) { notice.problem }

        before(:each) do
          number = 5
          @issue_link = "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets/#{number}.xml"
          body = "<ticket><number type=\"integer\">#{number}</number></ticket>"
          stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").
                       to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

          post :create_issue, :app_id => problem.app.id, :id => problem.id
          problem.reload
        end

        it "should redirect to problem page" do
          expect(response).to redirect_to( app_problem_path(problem.app, problem) )
        end
      end
    end

    context "absent issue tracker" do
      let(:problem) { Fabricate :problem }

      before(:each) do
        post :create_issue, :app_id => problem.app.id, :id => problem.id
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to( app_problem_path(problem.app, problem) )
      end
    end

    context "error during request to a tracker" do
      context "lighthouseapp tracker" do
        let(:tracker) { Fabricate :lighthouse_tracker }
        let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => tracker.app)) }

        before(:each) do
          stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").to_return(:status => 500)

          post :create_issue, :app_id => err.app.id, :id => err.problem.id
        end

        it "should redirect to problem page" do
          expect(response).to redirect_to( app_problem_path(err.app, err.problem) )
        end
      end
    end
  end

  describe "DELETE /apps/:app_id/problems/:id/unlink_issue" do
    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "problem with issue" do
      let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :issue_link => "http://some.host")) }

      before(:each) do
        delete :unlink_issue, :app_id => err.app.id, :id => err.problem.id
        err.problem.reload
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to( app_problem_path(err.app, err.problem) )
      end

      it "should clear issue link" do
        expect(err.problem.issue_link).to be_nil
      end
    end

    context "err without issue" do
      let(:err) { Fabricate :err }

      before(:each) do
        delete :unlink_issue, :app_id => err.app.id, :id => err.problem.id
        err.problem.reload
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to( app_problem_path(err.app, err.problem) )
      end
    end
  end

  describe "Bulk Actions" do
    before(:each) do
      sign_in Fabricate(:admin)
      @problem1 = Fabricate(:err, :problem => Fabricate(:problem_resolved)).problem
      @problem2 = Fabricate(:err, :problem => Fabricate(:problem)).problem
    end

    describe "POST /apps/:app_id/problems/destroy_all" do
      before do
        sign_in Fabricate(:admin)
        @app      = Fabricate(:app)
        @problem1 = Fabricate(:problem, :app=>@app)
        @problem2 = Fabricate(:problem, :app=>@app)
      end

      it "destroys all problems" do
        expect {
          post :destroy_all, :app_id => @app.id
        }.to change(Problem, :count).by(-2)
      end

      it "should redirect back to the app page" do
        request.env["HTTP_REFERER"] = edit_app_path(@app)
        patch :destroy_all, :app_id => @app.id
        expect(response).to redirect_to(edit_app_path(@app))
      end
    end

  end

end

