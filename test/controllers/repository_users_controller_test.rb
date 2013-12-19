require 'test_helper'

class RepositoryUsersControllerTest < ActionController::TestCase

  setup do
    @user = users(:non_admin)
    @enabled_user = users(:dm)

    @create_params = { repository_user: { email: 'floob3@baz.net', name: 'Jim floob' } }
    @update_params = {id: @user, repository_user: { email: 'floob3@flam.com' }}
  end

  context 'Not Authenticated' do
    should_not_get :index
    should_not_get :new

    should "not create user" do
      post :create, @create_params
      assert_redirected_to sessions_new_url(:target => repository_users_url(@create_params))
    end

    should "not show user" do
      get :show, id: @enabled_user
      assert_redirected_to sessions_new_url(:target => repository_user_url(@enabled_user))
    end

    should "not get edit" do
      get :edit, id: @user
      assert_redirected_to sessions_new_url(:target => edit_repository_user_url(@user))
    end

    should "not update user" do
      patch :update, @update_params
      assert_redirected_to sessions_new_url(:target => repository_user_url(@update_params))
    end

    should "not destroy user" do
      delete :destroy, id: @user
      assert_redirected_to sessions_new_url(:target => repository_user_url(@user))
    end
  end #Not Authenticated

  context 'Authenticated existing user without session' do
    setup do
      authenticate_existing_user(@user)
    end

    should_not_get :index, action: :create

    should "not show user" do
      get :show, id: @enabled_user
      assert_redirected_to sessions_create_url(:target => repository_user_url(@enabled_user))
    end

    should "not get edit" do
      get :edit, id: @user
      assert_redirected_to sessions_create_url(:target => edit_repository_user_url(@user))
    end

    should 'not get new if they already have an account' do
      get :new
      assert_redirected_to root_path()
      assert_not_nil assigns(:shib_user)
    end

    should 'not create if they already have an account' do
      assert_no_difference('RepositoryUser.count') do
        post :create, @create_params
      end
    end

    should "not update user" do
      patch :update, @update_params
      assert_redirected_to sessions_create_url(:target => repository_user_url(@update_params))
    end

    should "not destroy user" do
      delete :destroy, id: @user
      assert_redirected_to sessions_create_url(:target => repository_user_url(@user))
    end
  end #Authenticated witout session

  context 'Authenticated new user' do
    setup do
      @new_user = RepositoryUser.new(@create_params[:repository_user])
      @new_user.netid = 'floob123'
      authenticate_new_user(@new_user)
    end

    should_not_get :index, action: :create

    should "not show user" do
      get :show, id: @enabled_user
      assert_redirected_to sessions_create_url(:target => repository_user_url(@enabled_user))
    end

    should "not get edit" do
      get :edit, id: @user
      assert_redirected_to sessions_create_url(:target => edit_repository_user_url(@user))
    end

    should "get new" do
      get :new
      assert_response :success
      assert_not_nil assigns(:repository_user)
      assert_equal @request.env['HTTP_DISPLAYNAME'], assigns(:repository_user).name
      assert_equal @request.env['HTTP_MAIL'], assigns(:repository_user).email
    end

    should "create their own user" do
      assert_difference('RepositoryUser.count') do
        post :create, @create_params
      end

      @new_user = RepositoryUser.find(assigns(:repository_user).id)
      assert @new_user.is_enabled?, 'newly created user should be enabled'
      assert_equal @create_params[:repository_user][:name], @new_user.name
      assert_equal @create_params[:repository_user][:email], @new_user.email
      assert_equal @request.env['HTTP_UID'], @new_user.netid
      assert_redirected_to repository_user_path(assigns(:repository_user))
    end

    should "should ignore netid on create" do
      @create_params[:repository_user][:netid] = 'malory666'
      assert_difference('RepositoryUser.count') do
        post :create, @create_params
      end

      @new_user = RepositoryUser.find(assigns(:repository_user).id)
      assert_equal @create_params[:repository_user][:name], @new_user.name
      assert_equal @create_params[:repository_user][:email], @new_user.email
      assert_equal @request.env['HTTP_UID'], @new_user.netid
      assert_redirected_to repository_user_path(assigns(:repository_user))
    end

    should "not update user" do
      patch :update, @update_params
      assert_redirected_to sessions_create_url(:target => repository_user_url(@update_params))
    end

    should "not destroy user" do
      delete :destroy, id: @user
      assert_redirected_to sessions_create_url(:target => repository_user_url(@user))
    end

  end #Authenticated new user

  context 'Enabled NonAdmin with valid session' do
    setup do
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:repository_users)
    end

    should "not get new" do
      get :new
      assert_not_nil assigns(:shib_user)
      assert_redirected_to root_path()
    end

    should "not create user" do
      assert_no_difference('RepositoryUser.count') do
        post :create, @create_params
      end
      assert_redirected_to root_path()
    end

    should "show user" do
      get :show, id: @enabled_user
      assert_response :success
    end

    should 'not edit another user' do
      get :edit, id: @enabled_user
      assert_redirected_to root_path()
    end

    should "be able to edit their own account" do
      get :edit, id: @user
      assert_response :success
    end

    should "not update another user" do
      @update_params[:id] = @enabled_user.id
      patch :update, @update_params
      assert_redirected_to root_path()
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert_equal @enabled_user.email, @t_user.email
    end

    should "update their own account" do
      @update_params[:id] = @user.id
      patch :update, @update_params
      assert_not_nil assigns(:repository_user)
      assert_redirected_to repository_user_path(assigns(:repository_user))

      @t_user = RepositoryUser.find(@user.id)
      assert_equal @update_params[:repository_user][:email], @t_user.email
    end

    should "not destroy another user" do
      assert_no_difference('RepositoryUser.count') do
        delete :destroy, id: @enabled_user
      end
      assert_redirected_to root_path()
    end

    should "destroy user" do
      delete :destroy, id: @user
      assert_redirected_to repository_users_path
      @t_user = RepositoryUser.find(@user.id)
      assert !@t_user.is_enabled?, 'user should be disabled after destroy'
    end

    should 'not enable another user' do
      @enabled_user.is_enabled = false
      @enabled_user.save
      assert !@enabled_user.is_enabled, 'user should now be disabled'

      patch :update, id: @enabled_user, repository_user: { is_enabled: "true" }
      assert_redirected_to root_path()

      @t_user = RepositoryUser.find(@enabled_user.id)
      assert !@t_user.is_enabled?, 'user is enabled after update'
    end

    should 'not disable themselves' do
      assert @user.is_enabled?, 'user is not enabled before update'
      patch :update, id: @user, repository_user: { is_enabled: "false" }
      assert_redirected_to repository_user_path(@user)
      @t_user = RepositoryUser.find(@user.id)
      assert @t_user.is_enabled?, 'user is not enabled after update'
    end

    should 'not disable another user' do
      assert @enabled_user.is_enabled?, 'other user is not enabled before update'
      patch :update, id: @enabled_user, repository_user: { is_enabled: "false" }
      assert_redirected_to root_path()
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert @t_user.is_enabled?, 'user is not enabled after update'
    end
  end #Enabled NonAdmin with valid session

  context 'Disabled NonAdmin with valid session' do
    setup do
      @user.is_enabled = false
      @user.save
      authenticate_existing_user(@user, true)
    end

    should "not get index" do
      get :index
      assert_redirected_to repository_user_url(@user)
    end

    should "show themselves" do
      get :show, id: @user
      assert_response :success
      assert_not_nil assigns(:repository_user)
      assert_equal @user.id, assigns(:repository_user).id
    end

    should 'not show another user' do
      get :show, id: @enabled_user
      assert_redirected_to root_path()
    end

    should 'not edit another user' do
      get :edit, id: @enabled_user
      assert_redirected_to repository_user_url(@user)
    end

    should "not be able to edit their own account" do
      get :edit, id: @user
      assert_redirected_to repository_user_url(@user)
    end

    should "not update another user" do
      @update_params[:id] = @enabled_user.id
      patch :update, @update_params
      assert_redirected_to repository_user_url(@user)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert_equal @enabled_user.email, @t_user.email
    end

    should "not update their own account" do
      @update_params[:id] = @user.id
      patch :update, @update_params
      assert_redirected_to repository_user_url(@user)

      @t_user = RepositoryUser.find(@user.id)
      assert_equal @user.email, @t_user.email
    end

    should "not destroy another user" do
      assert_no_difference('RepositoryUser.count') do
        delete :destroy, id: @enabled_user
      end
      assert_redirected_to repository_user_url(@user)
    end

    should "not destroy themselves" do
      delete :destroy, id: @user
      assert_redirected_to repository_user_url(@user)
    end

    should 'not enable another user' do
      @enabled_user.is_enabled = false
      @enabled_user.save
      assert !@enabled_user.is_enabled, 'user should now be disabled'

      patch :update, id: @enabled_user, repository_user: { is_enabled: "true" }
      assert_redirected_to repository_user_url(@user)

      @t_user = RepositoryUser.find(@enabled_user.id)
      assert !@t_user.is_enabled?, 'user is enabled after update'
    end

    should 'not disable themselves' do
      patch :update, id: @user, repository_user: { is_enabled: "false" }
      assert_redirected_to repository_user_url(@user)
    end

    should 'not disable another user' do
      assert @enabled_user.is_enabled?, 'other user is not enabled before update'
      patch :update, id: @enabled_user, repository_user: { is_enabled: "false" }
      assert_redirected_to repository_user_url(@user)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert @t_user.is_enabled?, 'user is not enabled after update'
    end
  end #Disabled NonAdmin with valid session

  context 'Enabled Admin with valid session' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:repository_users)
    end

    should "not get new" do
      get :new
      assert_not_nil assigns(:shib_user)
      assert_redirected_to root_path()
    end

    should "not create user" do
      assert_no_difference('RepositoryUser.count') do
        post :create, @create_params
      end
      assert_redirected_to root_path()
    end

    should "show user" do
      get :show, id: @enabled_user
      assert_response :success
    end

    should 'edit another user' do
      get :edit, id: @enabled_user
      assert_response :success
    end

    should "be able to edit their own account" do
      get :edit, id: @user
      assert_response :success
    end

    should "not update another user account parameters" do
      @update_params[:id] = @enabled_user.id
      patch :update, @update_params
      assert_redirected_to repository_user_path(@enabled_user)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert_equal @enabled_user.email, @t_user.email
    end

    should "update their own account" do
      @update_params[:id] = @user.id
      patch :update, @update_params
      assert_not_nil assigns(:repository_user)
      assert_redirected_to repository_user_path(assigns(:repository_user))

      @t_user = RepositoryUser.find(@user.id)
      assert_equal @update_params[:repository_user][:email], @t_user.email
    end

    should 'make another user an administrator' do
      @enabled_user.is_administrator = false
      @enabled_user.save
      assert !@enabled_user.is_administrator?, 'enabled_user should not be an administrator'
      patch :update, id: @enabled_user, repository_user: {is_administrator: "true"}
      assert_redirected_to repository_user_path(@enabled_user)
      @t_u = RepositoryUser.find(@enabled_user.id)
      assert @t_u.is_administrator?, 'enabled_user should now be an administrator'
    end

    should 'make another administrator a non administrator' do
      @enabled_user.is_administrator = true
      @enabled_user.save
      assert @enabled_user.is_administrator?, 'enabled_user should be an administrator'
      patch :update, id: @enabled_user, repository_user: {is_administrator: "false"}
      assert_redirected_to repository_user_path(@enabled_user)
      @t_u = RepositoryUser.find(@enabled_user.id)
      assert !@t_u.is_administrator?, 'enabled_user should not now be an administrator'
    end

    should 'not become a non administrator' do
      assert @user.is_administrator?, 'user should be an administrator'
      patch :update, id: @user, repository_user: {is_administrator: "false"}
      assert_redirected_to repository_user_path(@user)
      @t_u = RepositoryUser.find(@user.id)
      assert @t_u.is_administrator?, 'enabled_user should still be an administrator'
    end

    should "destroy another user by disabling them" do
      assert @enabled_user.is_enabled?, 'other user is not enabled before destroy!'
      delete :destroy, id: @enabled_user
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert !@t_user.is_enabled?, 'other user is not disabled after destroy!'
    end

    should "not destroy themselves" do
      assert @user.is_enabled?, 'admin should be enabled before destroy'
      delete :destroy, id: @user
      assert_redirected_to root_path()
      @t_user = RepositoryUser.find(@user.id)
      assert @t_user.is_enabled?, 'admin should still be enabled after destroy'
    end

    should 'enable another user' do
      @enabled_user.is_enabled = false
      @enabled_user.save
      assert !@enabled_user.is_enabled, 'user should now be disabled'

      patch :update, id: @enabled_user, repository_user: { is_enabled: "true" }
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert @t_user.is_enabled?, 'user is still disabled after update'
    end

    should 'not disable themselves' do
      assert @user.is_enabled?, 'admin is not enabled before update'
      patch :update, id: @user, repository_user: { is_enabled: "false" }
      @t_user = RepositoryUser.find(@user.id)
      assert @t_user.is_enabled?, 'admin is still enabled after update'
    end

    should 'disable another user' do
      assert @enabled_user.is_enabled?, 'other user is not enabled before update'
      patch :update, id: @enabled_user, repository_user: { is_enabled: "false" }
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert !@t_user.is_enabled?, 'other user is still enabled after update'
    end
  end #Enabled Admin with valid session

  context 'Disabled Admin with valid session' do
    setup do
      @admin = users(:admin)
      @admin.is_enabled = false
      @admin.save
      authenticate_existing_user(@admin, true)
    end

    should "not get index" do
      get :index
      assert_redirected_to repository_user_url(@admin)
    end

    should "show themselves" do
      get :show, id: @admin
      assert_response :success
      assert_not_nil assigns(:repository_user)
      assert_equal @admin.id, assigns(:repository_user).id
    end

    should 'not show another user' do
      get :show, id: @enabled_user
      assert_redirected_to root_path()
    end

    should 'not edit another user' do
      get :edit, id: @enabled_user
      assert_redirected_to repository_user_url(@admin)
    end

    should "not be able to edit their own account" do
      get :edit, id: @admin
      assert_redirected_to repository_user_url(@admin)
    end

    should "not update another user account parameters" do
      @update_params[:id] = @enabled_user.id
      patch :update, @update_params
      assert_redirected_to repository_user_url(@admin)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert_equal @enabled_user.email, @t_user.email
    end

    should "not update their own account" do
      @update_params[:id] = @admin.id
      patch :update, @update_params
      assert_redirected_to repository_user_url(@admin)
      @t_user = RepositoryUser.find(@admin.id)
      assert_equal @admin.email, @t_user.email
    end

    should "not destroy another user by disabling them" do
      assert @enabled_user.is_enabled?, 'other user is not enabled before destroy!'
      delete :destroy, id: @enabled_user
      assert_redirected_to repository_user_url(@admin)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert @t_user.is_enabled?, 'other user should not be disabled after destroy!'
    end

    should "not destroy themselves by disabling themselves" do
      delete :destroy, id: @admin
      assert_redirected_to repository_user_url(@admin)
    end

    should 'not enable another user' do
      @enabled_user.is_enabled = false
      @enabled_user.save
      assert !@enabled_user.is_enabled, 'user should now be disabled'

      patch :update, id: @enabled_user, repository_user: { is_enabled: "true" }
      assert_redirected_to repository_user_url(@admin)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert !@t_user.is_enabled?, 'user should still be disabled after update'
    end

    should 'not disable themselves' do
      patch :update, id: @user, repository_user: { is_enabled: "false" }
      assert_redirected_to repository_user_url(@admin)
      @t_user = RepositoryUser.find(@user.id)
      assert @t_user.is_enabled?, 'user should still be enabled after update'
    end

    should 'not disable another user' do
      assert @enabled_user.is_enabled?, 'other user is not enabled before update'
      patch :update, id: @enabled_user, repository_user: { is_enabled: "false" }
      assert_redirected_to repository_user_url(@admin)
      @t_user = RepositoryUser.find(@enabled_user.id)
      assert @t_user.is_enabled?, 'other user should still be enabled after update'
    end
  end #Disabled Admin with valid session
end
