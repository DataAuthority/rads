require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @existing_user = users('non_repo_user')
  end

  context 'Not Authenticated' do
    should_not_get :index
    should_not_get :new

    should "not create user" do
      post :create, user: { name: @existing_user.name }
      assert_redirected_to sessions_new_url(:target => users_url(user: { name: @existing_user.name }))
    end

    should "not show user" do
      get :show, id: @existing_user
      assert_redirected_to sessions_new_url(:target => user_url(@existing_user))
    end

    should "not get edit" do
      get :edit, id: @existing_user
      assert_redirected_to sessions_new_url(:target => edit_user_url(@existing_user))
    end

    should "not update user" do
      patch :update, id: @existing_user, user: { name: @existing_user.name }
      assert_redirected_to sessions_new_url(:target => user_url(@existing_user, user: { name: @existing_user.name }))
    end

    should "not destroy user" do
      delete :destroy, id: @existing_user
      assert_redirected_to sessions_new_url(:target => user_url(@existing_user))
    end
  end #Not Authenticated

  context 'Authenticated without session' do
    setup do
      authenticate_existing_user(@existing_user)
    end

    should_not_get :index, action: :create
    should_not_get :new, action: :create

    should "not create user" do
      post :create, user: { name: @existing_user.name }
      assert_redirected_to sessions_create_url(:target => users_url(user: { name: @existing_user.name }))
    end

    should "not show user" do
      get :show, id: @existing_user
      assert_redirected_to sessions_create_url(:target => user_url(@existing_user))
    end

    should "not get edit" do
      get :edit, id: @existing_user
      assert_redirected_to sessions_create_url(:target => edit_user_url(@existing_user))
    end

    should "not update user" do
      patch :update, id: @existing_user, user: { name: @existing_user.name }
      assert_redirected_to sessions_create_url(:target => user_url(@existing_user, user: { name: @existing_user.name }))
    end

    should "not destroy user" do
      delete :destroy, id: @existing_user
      assert_redirected_to sessions_create_url(:target => user_url(@existing_user))
    end
  end #Authenticated witout session

  context 'Admin with valid session' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:users)
    end

    should "get new" do
      get :new
      assert_response :success
    end

    should "create user" do
      @user_params = {
        user: { 
          name: 'new_test_user'
        }
      }

      assert_difference('User.count') do
        post :create, @user_params
      end

      assert_redirected_to user_path(assigns(:user))
    end

    should "show user" do
      get :show, id: @existing_user
      assert_response :success
    end

    should "get edit" do
      get :edit, id: @existing_user
      assert_response :success
    end

    should "not allow an admin to become a non-admin" do
      assert @user.is_administrator?, 'user should be an administrator'
      patch :update, id: @user, user: { is_administrator: false }
      @t_u = RepositoryUser.find(@user.id)
      assert @t_u.is_administrator?, 'user should still be an administrator'
    end

    should "update user" do
      @user_params = { id: @existing_user, user: { name: 'new_name_for_enabled' }}
      patch :update, @user_params
      assert_redirected_to user_path(assigns(:user))

      @t_user = User.find(@existing_user.id)
      assert_equal @user_params[:user][:name], @t_user.name
    end

    should "destroy user by disabling them" do
      assert @existing_user.is_enabled?, 'existing_user should be enabled'
      delete :destroy, id: @existing_user
      assert_redirected_to users_path
      @t_user = User.find(@existing_user.id)
      assert  !@t_user.is_enabled?, 'existing_user should not be enabled after destroy'
    end

    should "not destroy themselves" do
      assert @user.is_enabled?, 'user should be enabled'
      delete :destroy, id: @user
      assert_response 403
      @t_user = User.find(@user.id)
      assert  @t_user.is_enabled?, 'user should still be enabled after destroy'
    end

    should 'enable user' do
      @existing_user.is_enabled = false
      @existing_user.save
      assert !@existing_user.is_enabled?, 'existing_user should not be enabled'

      patch :update, id: @existing_user, user: { is_enabled: "true" }
      assert_redirected_to user_path(assigns(:user))
      @t_user = User.find(@existing_user.id)
      assert @t_user.is_enabled?, 'user should now be enabled'
    end

    should 'make another user an administrator' do
      @existing_user.is_administrator = false
      @existing_user.save
      assert !@existing_user.is_administrator?, 'existing_user should not be an administrator'

      patch :update, id: @existing_user, user: { is_administrator: "true" }
      assert_redirected_to user_path(assigns(:user))
      @t_user = User.find(@existing_user.id)
      assert @t_user.is_administrator?, 'user should now be an administrator'
    end

    should 'make another administrator a non administrator' do
      @existing_user.is_administrator = true
      @existing_user.save
      assert @existing_user.is_administrator?, 'existing_user should be an administrator'

      patch :update, id: @existing_user, user: { is_administrator: "false" }
      assert_redirected_to user_path(assigns(:user))
      @t_user = User.find(@existing_user.id)
      assert !@t_user.is_administrator?, 'user should not be an administrator'
    end

    should 'disable user' do
      assert @existing_user.is_enabled?, 'existing_user should be enabled'
      patch :update, id: @existing_user, user: { is_enabled: "false" }
      assert_redirected_to user_path(assigns(:user))
      @t_user = User.find(@existing_user.id)
      assert !@t_user.is_enabled?, 'user should now be disabled'
    end

    should 'not disable themselves' do
      assert @user.is_enabled?, 'user should be enabled'
      patch :update, id: @existing_user, user: { is_enabled: "false" }
      @t_user = User.find(@user.id)
      assert @t_user.is_enabled?, 'user should still be enabled'
    end

  end #Admin with valid session

  context 'NonAdmin with valid session' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:users)
    end

    should "not get new" do
      get :new
      assert_response 403
    end

    should "not create user" do
      @user_params = {
        user: { 
          name: 'new_test_user'
        }
      }

      assert_no_difference('User.count') do
        post :create, @user_params
      end
      assert_response 403
    end

    should "show user" do
      get :show, id: @existing_user
      assert_response :success
    end

    should "not get edit" do
      get :edit, id: @existing_user
      assert_response 403
    end

    should "not update user" do
      old_name = @existing_user.name
      @user_params = { id: @existing_user, user: { name: 'new_name_for_enabled' }}
      patch :update, @user_params
      assert_response 403

      @t_user = User.find(@existing_user.id)
      assert_equal old_name, @t_user.name
    end

    should "not destroy user" do
      assert @existing_user.is_enabled?, 'existing_user should be enabled'
      delete :destroy, id: @existing_user
      assert_response 403
      @t_user = User.find(@existing_user.id)
      assert  @t_user.is_enabled?, 'existing_user should still be enabled after destroy'
    end

    should 'enable user' do
      @existing_user.is_enabled = false
      @existing_user.save
      assert !@existing_user.is_enabled?, 'existing_user should not be enabled'

      patch :update, id: @existing_user, user: { is_enabled: "true" }
      assert_response 403
      @t_user = User.find(@existing_user.id)
      assert !@t_user.is_enabled?, 'user should still be disabled'
    end

    should 'not disable user' do
      assert @existing_user.is_enabled?, 'existing_user should be enabled'
      patch :update, id: @existing_user, user: { is_enabled: "false" }
      assert_response 403
      @t_user = User.find(@existing_user.id)
      assert @t_user.is_enabled?, 'user should still be enabled'
    end

  end #NonAdmin with valid session
end
