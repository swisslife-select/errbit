require 'spec_helper'

describe UsersController do

  it_requires_authentication :for => {
      :edit    => :get,
      :update     => :patch,
  }

  it_requires_admin_privileges :for => {
    :index    => :get,
    :show     => :get,
    :destroy  => :delete
  }

  let(:admin) { Fabricate(:admin) }
  let(:user) { Fabricate(:user) }
  let(:other_user) { Fabricate(:user) }

  context 'Signed in as a regular user' do

    before do
      sign_in user
    end

    context "GET /users/:other_id/edit" do
      it "redirects to the home page" do
        get :edit, :id => other_user.id
        expect(response).to redirect_to(root_path)
      end
    end

    context "GET /users/:my_id/edit" do
      it 'finds the user' do
        get :edit, :id => user.id
        expect(assigns(:user)).to eq user
        expect(response).to render_template 'edit'
      end

    end

    context "patch /users/:other_id" do
      it "redirects to the home page" do
        patch :update, :id => other_user.id
        expect(response).to redirect_to(root_path)
      end
    end

    context "patch /users/:my_id/id" do
      context "when the update is successful" do
        it "redirects to the user's page" do
          patch :update, :id => user.to_param, :user => {:name => 'Kermit'}
          expect(response).to redirect_to(user_path(user))
        end

        it "should not be able to become an admin" do
          expect {
            patch :update, :id => user.to_param, :user => {:admin => true}
          }.to_not change {
            user.reload.admin
          }.from(false)
        end

        it "should be able to set per_page option" do
          patch :update, :id => user.to_param, :user => {:per_page => 555}
          expect(user.reload.per_page).to eq 555
        end

        it "should be able to set time_zone option" do
          patch :update, :id => user.to_param, :user => {:time_zone => "Warsaw"}
          expect(user.reload.time_zone).to eq "Warsaw"
        end

        it "should be able to not set github_login option" do
          patch :update, :id => user.to_param, :user => {:github_login => " "}
          expect(user.reload.github_login).to eq nil
        end

        it "should be able to set github_login option" do
          patch :update, :id => user.to_param, :user => {:github_login => "awesome_name"}
          expect(user.reload.github_login).to eq "awesome_name"
        end
      end

      context "when the update is unsuccessful" do
        it "renders the edit page" do
          patch :update, :id => user.to_param, :user => {:name => nil}
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  context 'Signed in as an admin' do
    before do
      sign_in admin
    end

    context "GET /users" do

      it 'respond success' do
        Fabricate(:user)
        get :index
        expect(response).to be_success
      end

    end

    context "GET /users/:id" do
      it 'finds the user' do
        get :show, :id => user.id
        expect(assigns(:user)).to eq user
        expect(response).to be_success
      end
    end

    context "GET /users/new" do
      it 'assigns a new user' do
        get :new
        expect(assigns(:user)).to be_a(User)
        expect(assigns(:user)).to be_new_record
        expect(response).to be_success
      end
    end

    context "POST /users" do
      context "when the create is successful" do
        let(:attrs) { {:user => Fabricate.attributes_for(:user)} }

        it "should be able to create admin" do
          attrs[:user][:admin] = true
          post :create, attrs
          expect(response).to be_redirect
          created_user = User.find_by! attrs[:email]
          expect(created_user.admin).to be_true
        end
      end
    end

    context "GET /users/:id/edit" do
      it 'finds the user' do
        get :edit, :id => user.id
        expect(assigns(:user)).to eq user
        expect(response).to be_success
      end
    end

    context "patch /users/:id" do
      context "when the update is successful" do
        before {
          patch :update, :id => user.to_param, :user => user_params
        }

        context "with normal params" do
          let(:user_params) { {:name => 'Kermit'} }
          it "sets a message to display" do
            expect(request.flash[:success]).to eq I18n.t('controllers.users.flash.update.success', :name => user.reload.name)
            expect(response).to redirect_to(user_path(user))
          end
        end
      end
      context "when the update is unsuccessful" do

        it "renders the edit page" do
          patch :update, :id => user.to_param, :user => {:name => nil}
          expect(response).to render_template(:edit)
        end
      end
    end

    context "DELETE /users/:id" do

      context "with a destroy success" do
        let(:user_destroy) { double(:destroy => true) }

        before {
          delete :destroy, :id => user.id
        }

        it 'should destroy user' do
          expect(response).to redirect_to(users_path)
          expect(User.exists?(user.id)).to be false
        end
      end

      context "with trying destroy himself" do
        before {
          delete :destroy, :id => admin.id
        }

        it 'should not destroy user' do
          expect(response).to redirect_to(root_path)
          expect(User.exists?(user.id)).to be true
        end
      end
    end

    describe "#user_params" do
      context "with current user not admin" do
        before {
          controller.stub(:current_user).and_return(user)
          controller.stub(:params).and_return(ActionController::Parameters.new(user_param))
        }
        let(:user_param) { {'user' => { :name => 'foo', :admin => true }} }
        it 'not have admin field' do
          expect(controller.send(:user_params)).to eq ({'name' => 'foo'})
        end
        context "with password and password_confirmation empty?" do
          let(:user_param) { {'user' => { :name => 'foo', 'password' => '', 'password_confirmation' => '' }} }
          it 'not have password and password_confirmation field' do
            expect(controller.send(:user_params)).to eq ({'name' => 'foo'})
          end
        end
      end

      context "with current user admin" do
        it 'have admin field'
        context "with password and password_confirmation empty?" do
          it 'not have password and password_confirmation field'
        end
        context "on his own user" do
          it 'not have admin field'
        end
      end
    end
  end

  context 'Guest' do
    context "POST /users" do
      context "when the create is successful" do
        let(:attrs) { {:user => Fabricate.attributes_for(:user)} }

        it "sets a message to display" do
          post :create, attrs
          expect(request.flash[:success]).to include('part of the team')
        end

        it "redirects to the root page" do
          post :create, attrs
          expect(response).to redirect_to(root_path)
        end

        it "should has auth token" do
          post :create, attrs
          expect(User.last.authentication_token).to_not be_blank
        end
      end

      context "when the create is unsuccessful" do
        let(:user) {
          Struct.new(:admin, :attributes).new(true, {})
        }
        before do
          expect(User).to receive(:new).and_return(user)
          expect(user).to receive(:save).and_return(false)
        end

        it "renders the new page" do
          post :create, :user => { :username => 'foo' }
          expect(response).to render_template(:new)
        end
      end
    end

  end

end
