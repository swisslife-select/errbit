require 'spec_helper'

describe AppsController do
  render_views

  let(:admin) { Fabricate(:admin) }
  let(:user) { Fabricate(:user) }
  let(:watcher) { Fabricate(:user_watcher, :app => app, :user => user) }
  let(:unwatched_app) { Fabricate(:app) }
  let(:app) { unwatched_app }
  let(:watched_app1) do
    a = Fabricate(:app)
    Fabricate(:user_watcher, :user => user, :app => a)
    a
  end
  let(:watched_app2) do
    a = Fabricate(:app)
    Fabricate(:user_watcher, :user => user, :app => a)
    a
  end
  let(:notice) do
    Fabricate(:notice, :problem => problem)
  end
  let(:problem) do
    Fabricate(:problem, :app => app)
  end
  let(:problem_resolved) { Fabricate(:problem_resolved, :app => app) }

  describe "GET /apps" do
    context 'when logged in as an admin' do
      before(:each) do
        sign_in admin
      end

      it 'finds all apps' do
        unwatched_app && watched_app1 && watched_app2
        get :index
        expect(assigns(:apps).entries).to eq App.all.sort.entries
        expect(response).to be_success
      end
    end

    context 'when logged in as a regular user' do
      before(:each) do
        sign_in user
      end

      it 'finds apps the user is watching' do
        watched_app1 && watched_app2 && unwatched_app
        get :index
        expect(assigns(:apps)).to include(watched_app1, watched_app2)
        expect(assigns(:apps)).to_not include(unwatched_app)
        expect(response).to be_success
      end
    end
  end

  describe "GET /apps/:id" do
    context 'logged in as an admin' do
      before(:each) do
        sign_in admin
      end

      it "should not raise errors for app with problem without notices" do
        problem
        expect{ get :show, :id => app.id }.to_not raise_error
      end

      it "should list atom feed successfully" do
        get :show, :id => app.id, :format => "atom"
        expect(response).to be_success
      end

      it "should list unresolved problems" do
        problem_resolved && problem
        get :show, :id => app.id
        expect(response).to be_success
        expect(assigns(:problems).all?(&:unresolved?)).to be_true
      end
    end
  end

  context 'logged in as an admin' do
    before do
      sign_in admin
    end

    describe "GET /apps/new" do
      it 'instantiates a new app with a prebuilt watcher' do
        get :new
        expect(assigns(:app)).to be_a(App)
        expect(assigns(:app)).to be_new_record
        expect(assigns(:app).watchers).to_not be_empty
        expect(response).to be_success
      end

      it "should copy attributes from an existing app" do
        repo_url = 'https://github.com/test/example'
        @app = Fabricate(:app_with_watcher, :name => "do not copy", :repo_url => repo_url)
        get :new, :copy_attributes_from => @app.id
        expect(assigns(:app)).to be_new_record
        expect(assigns(:app).name).to be_blank
        expect(assigns(:app).repo_url).to eq repo_url
        expect(assigns(:app).watchers.first.new_record?).to be true
        expect(response).to be_success
      end
    end

    describe "GET /apps/:id/edit" do
      it 'success' do
        app = Fabricate(:app)
        get :edit, id: app.id
        expect(response).to be_success
      end
    end

    describe "POST /apps" do
      let(:app_attrs) { Fabricate.attributes_for :app }

      context "when the create is successful" do
        it "should redirect to the app page" do
          post :create, :app => app_attrs
          expect(response).to redirect_to(app_path(assigns(:app)))
        end
      end
    end

    describe "patch /apps/:id" do
      before do
        @app = Fabricate(:app)
      end

      context "when the update is successful" do
        it "should redirect to the app page" do
          patch :update, :id => @app.id, :app => {}
          expect(response).to redirect_to(app_path(@app))
        end
      end

      context "changing name" do
        it "should redirect to app page" do
          id = @app.id
          patch :update, :id => id, :app => {:name => "new name"}
          @app.reload
          expect(response).to redirect_to(app_path(@app))
        end
      end

      context "when the update is unsuccessful" do
        it "should render the edit page" do
          patch :update, :id => @app.id, :app => { :name => '' }
          expect(response).to render_template(:edit)
        end
      end

      context "changing email_at_notices" do
        before do
          Errbit::Config.per_app_email_at_notices = true
        end

        it "should parse legal csv values" do
          patch :update, :id => @app.id, :app => { :email_at_notices => '1,   4,      7,8,  10' }
          @app.reload
          expect(@app.email_at_notices).to eq [1, 4, 7, 8, 10]
        end
        context "failed parsing of CSV" do
          it "should set the default value" do
            @app = Fabricate(:app, :email_at_notices => [1, 2, 3, 4])
            patch :update, :id => @app.id, :app => { :email_at_notices => 'asdf, -1,0,foobar,gd00,0,abc' }
            @app.reload
            expect(@app.email_at_notices).to eq Errbit::Config.email_at_notices
          end
        end
      end

      context "setting up issue tracker", :cur => true do
        context "unknown tracker type" do
          before(:each) do
            patch :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :type => 'unknown', :project_id => '1234', :api_token => '123123', :account => 'myapp'
            } }
            @app.reload
          end

          it "should not create issue tracker" do
            expect(@app.issue_tracker_configured?).to eq false
          end
        end

        IssueTracker.subclasses.each do |tracker_klass|
          context tracker_klass do
            it "should save tracker params" do
              params = tracker_klass::Fields.inject({}){|hash,f| hash[f[0]] = "test_value"; hash }
              params[:ticket_properties] = "card_type = defect" if tracker_klass == IssueTrackers::MingleTracker
              params[:type] = tracker_klass.to_s
              patch :update, :id => @app.id, :app => {:issue_tracker_attributes => params}

              @app.reload

              tracker = @app.issue_tracker
              expect(tracker).to be_a(tracker_klass)
              tracker_klass::Fields.each do |field, field_info|
                case field
                when :ticket_properties
                  expect(tracker.send(field.to_sym)).to eq 'card_type = defect'
                else
                  expect(tracker.send(field.to_sym)).to eq 'test_value'
                end
              end
            end

            it "should show validation notice when sufficient params are not present" do
              # Leave out one required param
              params = tracker_klass::Fields[1..-1].inject({}){|hash,f| hash[f[0]] = "test_value"; hash }
              params[:type] = tracker_klass.to_s
              patch :update, :id => @app.id, :app => {:issue_tracker_attributes => params}

              @app.reload
              expect(@app.issue_tracker_configured?).to eq false
            end
          end
        end
      end
    end

    describe "DELETE /apps/:id" do
      before do
        @app = Fabricate(:app)
      end

      it "should destroy the app" do
        delete :destroy, :id => @app.id
        expect(App.exists?(@app.id)).to be false
        expect(response).to redirect_to(apps_path)
      end
    end
  end

  describe "POST /apps/:id/regenerate_api_key" do
    context "like admin" do
      before do
        sign_in admin
      end

      it 'redirect_to app view' do
        expect do
          post :regenerate_api_key, :id => app.id
          expect(request).to redirect_to edit_app_path(app)
        end.to change { app.reload.api_key }
      end
    end

  end

end

