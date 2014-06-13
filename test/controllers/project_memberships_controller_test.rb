require 'test_helper'

class ProjectMembershipsControllerTest < ActionController::TestCase
  def self.should_pass_non_member_access_tests()
    should "not get :index to project/project_memberships with empty list of project_memberships" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :index, project_id: @project
      assert_response :success
      assert assigns(:project_memberships).empty?, 'project_memberships should be empty'
    end

    should "not get :new for project/project_membership" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :new, project_id: @project
      assert_redirected_to root_path()
    end

    should "not show project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :show, project_id: @project, id: @project.project_memberships.first
      assert_redirected_to root_path()
    end

    should "not create project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id }
      end
      assert_redirected_to root_path()
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
    end

    should "not destroy project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      assert_not_nil @existing_member
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @existing_member
      end
      assert_redirected_to root_path()
      assert @project.project_memberships.where(user_id: @existing_member.user_id).exists?, 'existing_member should still have a membership in project'
    end
  end

  def self.should_pass_non_admin_member_access_tests()
    should "get :index of project/project_memberships with memberships" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      get :index, project_id: @project
      assert_response :success
      assert_equal @project.project_memberships.count, assigns(:project_memberships).length
    end

    should "not get :new for project/project_membership" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      get :new, project_id: @project
      assert_redirected_to root_path()
    end

    should "show project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert_not_nil @existing_member
      get :show, project_id: @project, id: @existing_member
      assert_response :success
      assert_equal @existing_member.id, assigns(:project_membership).id
    end

    should "not create project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id }
      end
      assert_redirected_to root_path()
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
    end

    should "not destroy project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert_not_nil @existing_member
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @existing_member
      end
      assert_redirected_to root_path()
      assert @project.project_memberships.where(user_id: @existing_member.user_id).exists?, 'existing_member should still have a membership in project'
    end
  end

  def self.should_pass_administrator_member_access_tests
    should "get :index of project/project_memberships with memberships" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      get :index, project_id: @project
      assert_response :success
      assert_equal @project.project_memberships.count, assigns(:project_memberships).length
    end

    should "get :new for project/project_membership" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      get :new, project_id: @project
      assert_response :success
    end

    should "show project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      get :show, project_id: @project, id: @existing_member
      assert_response :success
      assert_equal @existing_member.id, assigns(:project_membership).id
    end

    should "create project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id }
      end
      assert_redirected_to project_path(@project)
      assert @project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should now have a membership in project'
    end

    should "destroy project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      assert_not_nil @existing_member
      assert_difference('ProjectMembership.count', -1) do
        delete :destroy, project_id: @project, id: @existing_member
      end
      assert_redirected_to project_path(@project)
      assert !@project.project_memberships.where(user_id: @existing_member.user_id).exists?, 'existing_member should no longer have a membership in project'
    end

    should 'not destroy their own project_membership in project' do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      assert_not_nil @existing_member
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @user_project_membership
      end
      assert_redirected_to root_path
      assert @project.project_memberships.where(user_id: @existing_member.user_id).exists?, 'self should still have a membership in project'
    end
  end

  setup do
    @project = projects(:membership_test)
    @project_membership = @project.project_memberships.first
    @existing_member = project_memberships(:project_membership_member)
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
      create_params = {project_id: @project.id, project_membership: { user_id: users(:non_admin).id }}
      assert_no_difference('ProjectMembership.count') do
        post :create, create_params
      end
      assert_redirected_to sessions_new_url(:target => project_project_memberships_url(create_params))
    end

    should "not destroy project_membership" do
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @project_membership
      end
      assert_redirected_to sessions_new_url(:target => project_project_membership_url(@project, @project_membership))
    end
  end #Not Authenticated

  context 'CoreUser without membership in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
    end

    should_pass_non_member_access_tests

  end #CoreUser without membership in Project

  context 'ProjectUser or ProjectUser without membership in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
    end

    should_pass_non_member_access_tests

  end #ProjectUser without membership in Project

  context 'CoreUser with producer role in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @user_project_membership = project_memberships(:project_membership_cu)
    end
    
    should_pass_non_admin_member_access_tests

  end #CoreUser with producer role in Project

 context 'ProjectUser with producer role in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @user_project_membership = project_memberships(:project_membership_pu)
    end
    
    should_pass_non_admin_member_access_tests

  end #ProjectUser with producer role in Project

  context 'Repositoryuser without membership in project' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should_pass_non_member_access_tests
  end #RepositoryUser without membership in project

  context 'RepositoryUser with producer role in project' do
    setup do
      @user = users(:p_m_producer)
      authenticate_existing_user(@user, true)
      @user_project_membership = project_memberships(:project_membership_producer)
    end

    should_pass_non_admin_member_access_tests

  end #RepositoryUser with producer in project

  context 'RepositoryUser with consumer role in project' do
    setup do
      @user = users(:p_m_consumer)

      authenticate_existing_user(@user, true)
      @user_project_membership = project_memberships(:project_membership_consumer)
    end

    should_pass_non_admin_member_access_tests

  end #RepositoryUser with consumer role in project

  context 'RepositoryUser with data_manager role in project' do
    setup do
      @user = users(:p_m_dmanager)

      authenticate_existing_user(@user, true)
      @user_project_membership = project_memberships(:project_membership_d_manager)
    end

    should_pass_non_admin_member_access_tests

  end #RepositoryUser with data_manager role in project

  context 'RepositoryUser with admin role in project' do
    setup do
      @user = users(:p_m_administrator)
      authenticate_existing_user(@user, true)
      @user_project_membership = @project.project_memberships.where(user_id: @user.id).first
    end

    should_pass_administrator_member_access_tests

  end #RepositoryUser with admin role in project
end
