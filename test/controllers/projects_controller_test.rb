require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @create_params = { project: { name: 'new_project', description: 'new project for testing' } }
  end

  context 'Not Authenticated' do
    should_not_get :index
    should_not_get :new

    should "not show project" do
      get :show, id: @project
      assert_redirected_to sessions_new_url(:target => project_url(@project))
    end

    should "not create project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
      end
      assert_redirected_to sessions_new_url(:target => projects_url(@create_params))
    end
  end #Not Authenticated

  context 'CoreUser' do
    setup do
      @user = users(:non_admin)
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
      assert_not_nil assigns(:projects)
    end

    should "get show" do
      get :show, id: @project
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end

    should "not create a project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
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
      assert_not_nil assigns(:projects)
    end

    should "get new" do
      get :new
      assert_response :success
      assert_not_nil assigns(:project)
    end

    should "get show" do
      get :show, id: @project
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end

    should "create a project, and be listed as the creator" do
      assert_difference('Project.count') do
        post :create, @create_params
        assert_not_nil assigns(:project)
        assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
    end
  end #RepositoryUser
end
