require 'test_helper'

class ProjectMembershipsControllerTest < ActionController::TestCase
  def self.should_pass_non_member_access_tests()
    should "not get :index to project/project_memberships with empty list of project_memberships" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :index, project_id: @project
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not get :new for project/project_membership" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :new, project_id: @project
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not show project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :show, project_id: @project, id: @project.project_memberships.first
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not edit project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      get :edit, project_id: @project, id: @project.project_memberships.first
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not update project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      pm = @project.project_memberships.first
      assert_not_nil pm
      was_data_consumer = pm.is_data_consumer
      new_status = pm.is_data_consumer ? false : true
      patch :update, project_id: @project, id: pm, project_membership: {is_data_consumer: new_status}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_pm = ProjectMembership.find(pm.id)
      if was_data_consumer
        assert pm.is_data_consumer, 'project_member should still be a data_consumer'
      else
        assert !pm.is_data_consumer, 'project_member should still not be a data_consumer'
      end
    end

    should "not create project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id }
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
    end

    should "not destroy project_membership for project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, "#{ @user.name } #{ @user.type } should not have a membership in project"
      assert_not_nil @existing_member
      assert_no_difference('ProjectMembership.count') do
        delete :destroy, project_id: @project, id: @existing_member
        assert_access_controlled_action
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
      assert_access_controlled_action
      assert_response :success
      assert_equal @project.project_memberships.count, assigns(:project_memberships).length
    end

    should "not get :new for project/project_membership" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      get :new, project_id: @project
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "show project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert_not_nil @existing_member
      get :show, project_id: @project, id: @existing_member
      assert_access_controlled_action
      assert_response :success
      assert_equal @existing_member.id, assigns(:project_membership).id
    end

    should "not edit project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert_not_nil @existing_member
      get :edit, project_id: @project, id: @existing_member
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not update project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert_not_nil @existing_member
      @existing_member.update(is_data_consumer: false)
      patch :update, project_id: @project, id: @existing_member, project_membership: {is_data_consumer: true}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_pm = ProjectMembership.find(@existing_member.id)
      assert !t_pm.is_data_consumer, 'project_member should still not be a data_consumer'
    end

    should "not create project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert !@user_project_membership.is_administrator?, 'user should not be an admin'
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id }
        assert_access_controlled_action
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
        assert_access_controlled_action
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
      assert_access_controlled_action
      assert_response :success
      assert_equal @project.project_memberships.count, assigns(:project_memberships).length
    end

    should "get :new for project/project_membership" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      get :new, project_id: @project
      assert_access_controlled_action
      assert_response :success
    end

    should "show project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      get :show, project_id: @project, id: @existing_member
      assert_access_controlled_action
      assert_response :success
      assert_equal @existing_member.id, assigns(:project_membership).id
    end

    should "get edit project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      get :edit, project_id: @project, id: @existing_member
      assert_access_controlled_action
      assert_response :success
      assert_equal @existing_member.id, assigns(:project_membership).id
    end

    should "update existing project_membership roles" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      @existing_member.update(is_data_consumer: false, is_data_producer: false, is_data_manager: false, is_administrator: false)
      assert !@existing_member.is_data_manager, 'existing_member should not be a data_manager'
      assert !@existing_member.is_data_producer, 'existing_member should not be a data_producer'
      assert !@existing_member.is_data_consumer, 'existing_member should not be a data_consumer'
      assert !@existing_member.is_administrator, 'existing_member should not be administrator'
      patch :update, project_id: @project, id: @existing_member, project_membership: {is_data_consumer: true, is_data_producer: true, is_data_manager: true, is_administrator: true}
      assert_access_controlled_action
      assert_redirected_to project_path(@project)
      t_pm = ProjectMembership.find(assigns(:project_membership).id)
      assert t_pm.is_data_manager, 'project_member should now be a data_manager'
      assert t_pm.is_data_producer, 'project_member should now be a data_producer'
      assert t_pm.is_data_consumer, 'project_member should now be a data_consumer'
      assert t_pm.is_administrator, 'project_member should now be an administrator'
    end

    should "not update a CoreUser to the administrator role" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      existing_member = project_memberships(:project_membership_cu)
      assert !existing_member.is_administrator?, 'existing_member should not be administrator'
      patch :update, project_id: @project, id: existing_member, project_membership: {is_data_producer: false, is_administrator: true}
      assert_access_controlled_action
      assert_redirected_to root_path
      t_pm = ProjectMembership.find(assigns(:project_membership).id)
      assert !t_pm.is_administrator, 'project_member should still not be an administrator'
      assert t_pm.is_data_producer, 'project_member should still be a data_producer'
    end

    should "not update a ProjectUser to the admin role" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      existing_member = project_memberships(:project_membership_pu)
      assert !existing_member.is_administrator, 'existing_member should not be administrator'
      patch :update, project_id: @project, id: existing_member, project_membership: {is_data_producer: false, is_administrator: true}
      assert_access_controlled_action
      assert_redirected_to root_path
      t_pm = ProjectMembership.find(assigns(:project_membership).id)
      assert !t_pm.is_administrator, 'project_member should still not be an administrator'
      assert t_pm.is_data_producer, 'project_member should still be a data_producer'
    end

    should "create project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id }
        assert_access_controlled_action
      end
      assert_redirected_to project_path(@project)
      assert @project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should now have a membership in project'
    end

    should "create project_membership with roles for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      assert !@project.project_memberships.where(user_id: users(:admin).id).exists?, 'admin should not have a membership in project'
      assert_not_equal @user.id, users(:admin).id
      assert_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: users(:admin).id, is_data_consumer: true, is_data_producer: true, is_data_manager: true, is_administrator: true}
        assert_access_controlled_action
      end
      assert_redirected_to project_path(@project)
      new_pm = @project.project_memberships.where(user_id: users(:admin).id).first
      assert_not_nil new_pm, 'admin should now have a membership in project'
      assert new_pm.is_administrator, 'admin should be an administrator'
      assert new_pm.is_data_consumer, 'admin should be a data_consumer'
      assert new_pm.is_data_producer, 'admin should be a data_producer'
      assert new_pm.is_data_manager, 'admin should be a data_manager'
    end

    should 'not create a project_membership for a CoreUser with the administrator role' do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      new_member = users(:core_user)
      assert !@project.project_memberships.where(user_id: new_member.id).exists?, 'core_user should not have a membership in project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: new_member.id,is_data_consumer: true, is_data_producer: true, is_data_manager: true, is_administrator: true}
        assert_access_controlled_action
      end
      assert_redirected_to root_path
      assert !@project.project_memberships.where(user_id: new_member.id).exists?, 'core_user should still not have a membership'
    end

    should 'not create a project_membership for a ProjectUser with the administrator role' do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      new_member = users(:project_user)
      assert !@project.project_memberships.where(user_id: new_member.id).exists?, 'core_user should not have a membership in project'
      assert_no_difference('ProjectMembership.count') do
        post :create, project_id: @project, project_membership: { user_id: new_member.id,is_data_consumer: true, is_data_producer: true, is_data_manager: true, is_administrator: true}
        assert_access_controlled_action
      end
      assert_redirected_to root_path
      assert !@project.project_memberships.where(user_id: new_member.id).exists?, 'core_user should still not have a membership'
    end

    should "destroy project_membership for project" do
      assert_not_nil @user_project_membership, "#{ @user.name } #{ @user.type } should have a membership in project"
      assert @user_project_membership.is_administrator?, 'user should be an admin'
      assert_not_nil @existing_member
      assert_difference('ProjectMembership.count', -1) do
        delete :destroy, project_id: @project, id: @existing_member
        assert_access_controlled_action
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
        assert_access_controlled_action
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

  context 'CoreUser without membership in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_user(@actual_user)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
    end

    should_pass_non_member_access_tests

  end #CoreUser without membership in Project

  context 'ProjectUser without membership in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_user(@actual_user)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
    end

    should_pass_non_member_access_tests

  end #ProjectUser without membership in Project

  context 'CoreUser with producer role in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_user(@actual_user)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @user_project_membership = project_memberships(:project_membership_cu)
    end

    should_pass_non_admin_member_access_tests

  end #CoreUser with producer role in Project

 context 'ProjectUser with producer role in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_user(@actual_user)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @user_project_membership = project_memberships(:project_membership_pu)
    end

    should_pass_non_admin_member_access_tests

  end #ProjectUser with producer role in Project

  context 'Repositoryuser without membership in project' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
    end

    should_pass_non_member_access_tests
  end #RepositoryUser without membership in project

  context 'RepositoryUser with producer role in project' do
    setup do
      @user = users(:p_m_producer)
      authenticate_user(@user)
      @user_project_membership = project_memberships(:project_membership_producer)
    end

    should_pass_non_admin_member_access_tests

  end #RepositoryUser with producer in project

  context 'RepositoryUser with consumer role in project' do
    setup do
      @user = users(:p_m_consumer)

      authenticate_user(@user)
      @user_project_membership = project_memberships(:project_membership_consumer)
    end

    should_pass_non_admin_member_access_tests

  end #RepositoryUser with consumer role in project

  context 'RepositoryUser with data_manager role in project' do
    setup do
      @user = users(:p_m_dmanager)

      authenticate_user(@user)
      @user_project_membership = project_memberships(:project_membership_d_manager)
    end

    should_pass_non_admin_member_access_tests

  end #RepositoryUser with data_manager role in project

  context 'RepositoryUser with admin role in project' do
    setup do
      @user = users(:p_m_administrator)
      authenticate_user(@user)
      @user_project_membership = @project.project_memberships.where(user_id: @user.id).first
    end

    should_pass_administrator_member_access_tests

  end #RepositoryUser with admin role in project

end
