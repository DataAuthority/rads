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
      assert_redirected_to root_path()
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
      assert_redirected_to root_path()
    end
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
      @other_project = projects(:two)
    end

    should "not get :new" do
      get :new
      assert_redirected_to root_path()
    end

    should "get index" do
      get :index
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:projects)
    end

    should "get show on its own project" do
      get :show, id: @project
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end

    should "get show on other project" do
      get :show, id: @other_project
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @other_project.id, assigns(:project).id
    end

    should "not create a project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
      end
      assert_equal @puppet.id, @controller.current_user.id
      assert_redirected_to root_path()
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
        assert_difference('ProjectUser.count') do
          post :create, @create_params
          assert_not_nil assigns(:project)
          assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
      assert @t_project.project_memberships.where(user_id: @user.id).exists?, 'creator should have a new project_membership for the project'
    end
  end #RepositoryUser

  context 'ProjectMember' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)      
    end

    should 'be able to edit the project' do
      assert @project.is_member?(@user), 'user should be a member of the project'
      get :edit, id: @project
      assert_response :success
    end

    should 'be able to update the project' do
      new_description = "NEW DESCRIPTION"
      patch :update, id: @project, project: {description: new_description }
      assert_redirected_to project_path(@project)
      t_p = Project.find(@project.id)
      assert_equal new_description, t_p.description
    end
  end #ProjectMember

  context 'NonMember' do
    setup do
      @user = users(:dm)
      authenticate_existing_user(@user, true)      
    end

    should 'not be able to edit the project' do
      assert !@project.is_member?(@user), 'user should not be a member of the project'
      get :edit, id: @project
      assert_redirected_to root_path()
    end

    should 'not be able to update the project' do
      new_description = "NEW DESCRIPTION"
      old_description = @project.description
      patch :update, id: @project, project: {description: new_description }
      assert_redirected_to root_path()
      t_p = Project.find(@project.id)
      assert_equal old_description, @project.description
    end
  end
end
