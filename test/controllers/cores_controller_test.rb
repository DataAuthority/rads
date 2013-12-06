require 'test_helper'

class CoresControllerTest < ActionController::TestCase
  setup do
    @core = cores(:one)
    @create_params = { core: { name: 'new_core', description: 'new core for testing' } }
  end

  context 'Not Authenticated' do
    should_not_get :index
    should_not_get :new

    should "not show core" do
      get :show, id: @core
      assert_redirected_to sessions_new_url(:target => core_url(@core))
    end

    should "not create core" do
      assert_no_difference('Core.count') do
        assert_no_difference('CoreMembership.count') do
          post :create, @create_params
        end
      end
      assert_redirected_to sessions_new_url(:target => cores_url(@create_params))
    end
  end #Not Authenticated

  context 'CoreUser' do
    setup do
      @user = users(:non_admin)
      @other_core = cores(:two)
      authenticate_existing_user(@user, true)
      @puppet = users(:core_user)
      session[:switch_to_user_id] = @puppet.id
    end

    should "not get :new" do
      get :new
      assert_response 403
    end

    should "get index" do
      get :index
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:cores)
    end

    should "get show on its own core" do
      assert_equal @core.id, @puppet.core_id
      get :show, id: @core
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:core)
      assert_equal @core.id, assigns(:core).id
    end

    should "not get show on another core" do
      assert @other_core.id != @puppet.core_id
      get :show, id: @other_core
      assert_response 403
    end
      
    should "not create a core" do
      assert_no_difference('Core.count') do
        assert_no_difference('CoreMembership.count') do
          post :create, @create_params
        end
      end
      assert_equal @puppet.id, @controller.current_user.id
      assert_response 403
    end
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      @other_core = cores(:two)
      authenticate_existing_user(@user, true)
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
    end

    should "not get :new" do
      get :new
      assert_response 403
    end

    should "not get index" do
      get :index
      assert_equal @puppet.id, @controller.current_user.id
      assert_response 403
    end

    should "not get show" do
      get :show, id: @core
      assert_equal @puppet.id, @controller.current_user.id
      assert_response 403
    end

    should "not create a core" do
      assert_no_difference('Core.count') do
        assert_no_difference('CoreMembership.count') do
          post :create, @create_params
        end
      end
      assert_equal @puppet.id, @controller.current_user.id
      assert_response 403
    end
  end #ProjectUser

  context 'RepositoryUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:cores)
    end

    should "get new" do
      get :new
      assert_response :success
      assert_not_nil assigns(:core)
    end

    should "get show" do
      get :show, id: @core
      assert_response :success
      assert_not_nil assigns(:core)
      assert_equal @core.id, assigns(:core).id
    end

    should "create a core, and be listed as the creator" do
      assert_difference('Core.count') do
        assert_difference('CoreUser.count') do
          post :create, @create_params
          assert_not_nil assigns(:core)
          assert assigns(:core).valid?, "#{ assigns(:core).errors.messages.inspect }"
        end
      end
      assert_not_nil assigns(:core)
      assert_redirected_to core_path(assigns(:core))
      @t_core = Core.find(assigns(:core).id)
      assert_equal @user.id, @t_core.creator_id
      assert @t_core.core_memberships.where(repository_user_id: @user.id).exists?, 'creator should have a new core_membership for the core'
    end
  end #RepositoryUser
end
