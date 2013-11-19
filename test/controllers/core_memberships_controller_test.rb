require 'test_helper'

class CoreMembershipsControllerTest < ActionController::TestCase

  setup do
    @core = cores(:one)
    @core_membership = @core.core_memberships.first
    @create_params = {core_id: @core.id, core_membership: { repository_user_id: users(:admin).id }}
  end

  context 'Not Authenticated' do
    should "not get :index" do
      get :index, core_id: @core
      assert_redirected_to sessions_new_url(:target => core_core_memberships_url(@core))
    end

    should "not get :new" do
      get :new, core_id: @core
      assert_redirected_to sessions_new_url(:target => new_core_core_membership_url(@core))
    end

    should "not show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_redirected_to sessions_new_url(:target => core_core_membership_url(@core, @core_membership))
    end

    should "not create core_membership" do
      assert_no_difference('CoreMembership.count') do
        post :create, @create_params
      end
      assert_redirected_to sessions_new_url(:target => core_core_memberships_url(@create_params))
    end

    should "not destroy core_membership" do
      assert_no_difference('CoreMembership.count') do
        delete :destroy, core_id: @core, id: @core_membership
      end
      assert_redirected_to sessions_new_url(:target => core_core_membership_url(@core, @core_membership))
    end
  end #Not Authenticated

  context 'Non-RepositoryUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @puppet = users(:non_repo_user)
      session[:switch_to_user_id] = @puppet.id
    end

    should "not get :index" do
      get :index, core_id: @core
      assert_response 403
    end

    should "not get :new" do
      get :new, core_id: @core
      assert_response 403
    end

    should "not show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_response 403
    end

    should "not create core_membership" do
      assert_no_difference('CoreMembership.count') do
        post :create, @create_params
      end
      assert_response 403
    end

    should "not destroy core_membership" do
      assert_no_difference('CoreMembership.count') do
        delete :destroy, core_id: @core, id: @core_membership
      end
      assert_response 403
    end
  end #Non-RepositoryUser

  context 'Non Core Member' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should "not get :index" do
      get :index, core_id: @core
      assert_response :success
      assert assigns(:core_memberships).empty?, 'core_memberships should be empty'
    end

    should "not get :new" do
      get :new, core_id: @core
      assert_response 403
    end

    should "not show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_response 403
    end

    should "not create core_membership" do
      assert_no_difference('CoreMembership.count') do
        post :create, @create_params
      end
      assert_response 403
    end

    should "not destroy core_membership" do
      assert_no_difference('CoreMembership.count') do
        delete :destroy, core_id: @core, id: @core_membership
      end
      assert_response 403
    end
  end #Non Core Member

  context 'Core Member' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should "get :index" do
      get :index, core_id: @core
      assert_response :success
    end

    should "get :new" do
      get :new, core_id: @core
      assert_response :success
      assert_not_nil assigns(:core_membership)
      assert_equal @core.id, assigns(:core_membership).core_id
    end

    should "show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_response :success
    end

    should "create core_membership" do
      assert_difference('CoreMembership.count') do
        post :create, @create_params
        assert_not_nil assigns(:core_membership)
        assert assigns(:core_membership).errors.messages.empty?, "#{ assigns(:core_membership).errors.messages.inspect }"
        assert assigns(:core_membership).valid?, "#{ assigns(:core_membership).errors.inspect }"
      end
      assert_redirected_to core_core_membership_url(@core, assigns(:core_membership))
    end

    should "destroy core_membership" do
      assert_difference('CoreMembership.count', -1) do
        delete :destroy, core_id: @core, id: @core_membership
      end
      assert_redirected_to core_core_memberships_url(@core)
    end

  end #Core Member
end
