require 'test_helper'

class ProjectUsersControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_user = @project.project_user
    @other_project = projects(:two)
    @other_project_user = @other_project.project_user
  end

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
      session[:switch_to_user_id] = @project_user.id
    end

    should 'not get index' do
      get :index
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should 'not update ProjectUser' do
      @other_project_user.is_enabled = false
      @other_project_user.save
      assert !@other_project_user.is_enabled?, 'project_user should not be enabled'
      patch :update, id: @other_project_user, project_user: {is_enabled: true}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_u = ProjectUser.find(@other_project_user.id)
      assert !t_u.is_enabled?, 'project_user should still not be enabled'
    end

    should 'not destroy any ProjectUser' do
      ProjectUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('ProjectUser.count') do
          delete :destroy, id: cu
          assert_access_controlled_action
          assert_redirected_to root_path()
        end
        t_u = ProjectUser.find(cu.id)
        assert t_u.is_enabled?, "#{ t_u.name } should still be enabled"
      end
    end
  end #ProjectUser

  context 'NonAdmin' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
    end

    should 'not get index' do
      get :index
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should 'not update ProjectUser' do
      @project_user.is_enabled = false
      @project_user.save
      assert !@project_user.is_enabled?, 'project_user should be enabled'
      patch :update, id: @project_user, project_user: {is_enabled: true}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_u = ProjectUser.find(@project_user.id)
      assert !t_u.is_enabled?, 'project_user should still not be enabled'
    end

    should 'not destroy any ProjectUser' do
      ProjectUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('ProjectUser.count') do
          delete :destroy, id: cu
          assert_access_controlled_action
          assert_redirected_to root_path()
        end
        t_u = ProjectUser.find(cu.id)
        assert t_u.is_enabled?, "#{ t_u.name } should still be enabled"
      end
    end
  end #NonAdmin

  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_user(@user)
    end

    should 'get index with all ProjectUsers' do
      get :index
      assert_access_controlled_action
      assert_response :success
      assert_not_nil assigns(:project_users)
      count = assigns(:project_users).count
      assert count > 0, 'there should be some project_users'
      assert_equal ProjectUser.count, count
    end

    should 'update ProjectUser to enable them' do
      @project_user.is_enabled = false
      @project_user.save
      assert !@project_user.is_enabled?, 'project_user should be enabled'
      patch :update, id: @project_user, project_user: {is_enabled: true}
      assert_access_controlled_action
      t_u = ProjectUser.find(@project_user.id)
      assert t_u.is_enabled?, 'project_user should still now be enabled'
    end

    should 'destroy any ProjectUser by disabling' do
      assert @project_user.is_enabled?, "#{ @project_user.name } should be enabled"
      assert_no_difference('ProjectUser.count') do
        delete :destroy, id: @project_user
        assert_access_controlled_action
      end
      t_u = ProjectUser.find(@project_user.id)
      assert !t_u.is_enabled?, "#{ t_u.name } should not now be enabled"
    end
  end #Admin
end
