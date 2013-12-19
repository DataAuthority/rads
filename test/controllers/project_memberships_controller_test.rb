require 'test_helper'

class ProjectMembershipsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_membership = @project.project_memberships.first
    @create_params = {project_id: @project.id, project_membership: { user_id: users(:admin).id }}
  end

  context 'Not Authenticated' do
    should "not get :index" do
      get :index, project_id: @project
      assert_redirected_to sessions_new_url(:target => project_project_memberships_url(@project))
    end

    should "not get :new" do
      get :new, project_id: @project
      assert_redirected_to sessions_new_url(:target => new_project_project_membership_url(@project))
    end

    should "not show project_membership" do
      get :show, project_id: @project, id: @project_membership
      assert_redirected_to sessions_new_url(:target => project_project_membership_url(@project, @project_membership))
    end

    should "not create project_membership" do
      assert_no_difference('ProjectMembership.count') do
        post :create, @create_params
      end
      assert_redirected_to sessions_new_url(:target => project_project_memberships_url(@create_params))
    end

    should "not destroy project_membership" do
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @project_membership
      end
      assert_redirected_to sessions_new_url(:target => project_project_membership_url(@project, @project_membership))
    end
  end #Not Authenticated

  context 'CoreUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @puppet = users(:core_user)
      session[:switch_to_user_id] = @puppet.id
      @project_with_membership = projects(:two)
      @project_without_membership = @project
    end

    should "not get :index to project without membership" do
      assert !@project_without_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should not have a membership in project_without_membership'
      get :index, project_id: @project_without_membership
      assert_response :success
      assert assigns(:project_memberships).empty?, 'project_memberships should be empty'
    end

    should "get :index to project with membership" do
      assert @project_with_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should have a membership in project_with_membership'
      get :index, project_id: @project_with_membership
      assert_response :success
      assert_not_nil assigns(:project_memberships)
    end

    should "not get :new for project without membership" do
      assert !@project_without_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should not have a membership in project_without_membership'
      get :new, project_id: @project_without_membership
      assert_redirected_to root_path()
    end

    should "not get :new for project with membership" do
      assert @project_with_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should have a membership in project_with_membership'
      get :new, project_id: @project_with_membership
      assert_redirected_to root_path()
    end

    should "not show project_membership for project without membership" do
      assert !@project_without_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should not have a membership in project_without_membership'
      get :show, project_id: @project_without_membership, id: @project_without_membership.project_memberships.first
      assert_redirected_to root_path()
    end

    should "show project_membership for project with membership" do
      assert @project_with_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should have a membership in project_with_membership'
      get :show, project_id: @project_with_membership, id: @project_with_membership.project_memberships.first
      assert_response :success
      assert_not_nil assigns(:project_membership)
      assert_equal @project_with_membership.project_memberships.first.id, assigns(:project_membership).id
    end

    should "not create project_membership for project without membership" do
      assert !@project_without_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should not have a membership in project_without_membership'
      assert !@project_without_membership.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project_without_membership'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project_without_membership, project_membership: { user_id: users(:admin).id }
      end
      assert_redirected_to root_path()
      assert !@project_without_membership.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project_without_membership'
    end

    should "not create project_membership for project with membership" do
      assert @project_with_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should have a membership in project_with_membership'
      assert !@project_with_membership.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should not have a membership in project_with_membership'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project_with_membership, project_membership: { user_id: users(:non_admin).id }
      end
      assert_redirected_to root_path()
      assert !@project_with_membership.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should not have a membership in project_with_membership'
    end

    should "not destroy project_membership for project without membership" do
      assert !@project_without_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should not have a membership in project_without_membership'
      assert @project_without_membership.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should have a membership in project_without_membership'
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project_without_membership, id: project_memberships(:one).id
      end
      assert_redirected_to root_path()
      assert @project_without_membership.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should have a membership in project_without_membership'
    end

    should "not destroy project_membership for project with membership" do
      assert @project_with_membership.project_memberships.where(user_id: @puppet.id).exists?, 'core_user should have a membership in project_with_membership'
      assert @project_with_membership.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should have a membership in project_with_membership'
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project_with_membership, id: project_memberships(:three).id
      end
      assert_redirected_to root_path()
      assert @project_without_membership.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should have a membership in project_without_membership'
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

    should "get :index to other project with empty project_memberships" do
      get :index, project_id: @other_project
      assert_response :success
      assert assigns(:project_memberships).empty?, 'project_memberships should be empty'
    end

    should "get :index to its own project" do
      get :index, project_id: @puppet.project_id
      assert_response :success
    end

    should "not get :new for other project" do
      get :new, project_id: @other_project
      assert_redirected_to root_path()
    end

    should "not get :new for its own project" do
      get :new, project_id: @puppet.project_id
      assert_redirected_to root_path()
    end

    should "not show project_membership for other project" do
      get :show, project_id: @other_project, id: @other_project.project_memberships.first
      assert_redirected_to root_path()
    end

    should "not show project_membership for its own project" do
      get :show, project_id: @puppet.project_id, id: @puppet.project.project_memberships.first
      assert_redirected_to root_path()
    end

    should "not create project_membership for other project" do
      assert !@other_project.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should not have a membership in other project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @other_project, project_membership: { user_id: users(:non_admin).id }
      end
      assert_redirected_to root_path()
      assert !@other_project.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should not have a membership in other_project'
    end

    should "not create project_membership for its own project" do
      assert !@puppet.project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in puppet.project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @puppet.project_id, project_membership: { user_id: users(:admin).id }
      end
      assert_redirected_to root_path()
      assert !@puppet.project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in puppet.project'
    end

    should "not destroy project_membership for other project" do
      assert @other_project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should have a membership in other_project'
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @other_project, id: @other_project.project_memberships.where(user_id: users(:admin).id).first.id
      end
      assert_redirected_to root_path()
      assert @other_project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should have a membership in other_project'
    end

    should "not destroy project_membership for its own project" do
      assert @puppet.project.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should have a membership in puppet.project'
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @puppet.project_id, id: @puppet.project.project_memberships.where(user_id: users(:non_admin).id).first.id
      end
      assert_redirected_to root_path()
      assert @puppet.project.project_memberships.where(user_id: users(:non_admin).id).exists?, 'non_admin should have a membership in puppet.project'
    end
  end #ProjectUser

  context 'Repositoryuser Non Project Member' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should "not get :index" do
      get :index, project_id: @project
      assert_response :success
      assert assigns(:project_memberships).empty?, 'project_memberships should be empty'
    end

    should "not get :new" do
      get :new, project_id: @project
      assert_redirected_to root_path()
    end

    should "not show project_membership" do
      get :show, project_id: @project, id: @project_membership
      assert_redirected_to root_path()
    end

    should "not create project_membership" do
      assert_no_difference('ProjectMembership.count') do
        post :create, @create_params
      end
      assert_redirected_to root_path()
    end

    should "not destroy project_membership" do
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @project_membership
      end
      assert_redirected_to root_path()
    end
  end #RepositoryUser Non Project Member

  context 'RepositoryUser Project Member' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should "get :index" do
      get :index, project_id: @project
      assert_response :success
    end

    should "get :new" do
      get :new, project_id: @project
      assert_response :success
      assert_not_nil assigns(:project_membership)
      assert_equal @project.id, assigns(:project_membership).project_id
      assert @project.project_memberships.count > 0, 'there should be at least one project_membership'
      assert_not_nil assigns(:non_members)
      assert assigns(:non_members).include?(users(:admin)), 'admin should be in the list of non_members'
      assert !assigns(:non_members).include?(users(:non_admin)), 'non_admin should not be in the list of non_members'
    end

    should "show project_membership" do
      get :show, project_id: @project, id: @project_membership
      assert_response :success
    end

    should "create project_membership" do
      assert_difference('ProjectMembership.count') do
        post :create, @create_params
        assert_not_nil assigns(:project_membership)
        assert assigns(:project_membership).errors.messages.empty?, "#{ assigns(:project_membership).errors.messages.inspect }"
        assert assigns(:project_membership).valid?, "#{ assigns(:project_membership).errors.inspect }"
      end
      assert_redirected_to project_project_membership_url(@project, assigns(:project_membership))
    end

    should "destroy project_membership" do
      assert_difference('ProjectMembership.count', -1) do
        delete :destroy, project_id: @project, id: @project_membership
      end
      assert_redirected_to project_project_memberships_url(@project)
    end

  end #RepositoryUser Project Member
end
