require 'test_helper'

class ProjectUsersControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_user = @project.project_user
    @other_project = projects(:two)
    @other_project_user = @other_project.project_user
  end

  context 'nil user' do
    should 'not get index' do
      get :index
      assert_redirected_to sessions_new_url(:target => project_users_url)
    end

    should 'not update ProjectUser' do
      @project_user.is_enabled = false
      @project_user.save
      assert !@project_user.is_enabled?, 'project_user should not be enabled'
      patch :update, id: @project_user, project_user: {is_enabled: true}
      assert_redirected_to sessions_new_url(target: project_user_url(@project_user, {project_user: {is_enabled: true}}))
      t_u = ProjectUser.find(@project_user.id)
      assert !t_u.is_enabled?, 'project_user should still not be enabled'
    end

    should 'not destroy any ProjectUser' do
      ProjectUser.all.each do |cu|
        assert_no_difference('ProjectUser.count') do
          delete :destroy, id: cu
          assert_redirected_to sessions_new_url(:target => project_user_url(cu))
        end
      end
    end
  end #nil user

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      session[:switch_to_user_id] = @project_user.id
    end

    should 'get index with empty project_users' do
      get :index
      assert_response :success
      assert_not_nil assigns(:project_users)
      assert assigns(:project_users).empty?, 'project_users should be empty'
    end

    should 'not update ProjectUser' do
      @other_project_user.is_enabled = false
      @other_project_user.save
      assert !@other_project_user.is_enabled?, 'project_user should not be enabled'
      patch :update, id: @other_project_user, project_user: {is_enabled: true}
      assert_response 403
      t_u = ProjectUser.find(@other_project_user.id)
      assert !t_u.is_enabled?, 'project_user should still not be enabled'
    end

    should 'not destroy any ProjectUser' do
      ProjectUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('ProjectUser.count') do
          delete :destroy, id: cu
          assert_response 403
        end
        t_u = ProjectUser.find(cu.id)
        assert t_u.is_enabled?, "#{ t_u.name } should still be enabled"
      end
    end
  end #ProjectUser

  context 'NonAdmin' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should 'get index with empty project_users' do
      get :index
      assert_response :success
      assert_not_nil assigns(:project_users)
      assert assigns(:project_users).empty?, 'there should be no project_users'
    end

    should 'not update ProjectUser' do
      @project_user.is_enabled = false
      @project_user.save
      assert !@project_user.is_enabled?, 'project_user should be enabled'
      patch :update, id: @project_user, project_user: {is_enabled: true}
      assert_response 403
      t_u = ProjectUser.find(@project_user.id)
      assert !t_u.is_enabled?, 'project_user should still not be enabled'
    end

    should 'not destroy any ProjectUser' do
      ProjectUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('ProjectUser.count') do
          delete :destroy, id: cu
          assert_response 403
        end
        t_u = ProjectUser.find(cu.id)
        assert t_u.is_enabled?, "#{ t_u.name } should still be enabled"
      end
    end
  end #NonAdmin

  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should 'get index with all ProjectUsers' do
      get :index
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
      t_u = ProjectUser.find(@project_user.id)
      assert t_u.is_enabled?, 'project_user should still now be enabled'
    end

    should 'destroy any ProjectUser by disabling' do
      assert @project_user.is_enabled?, "#{ @project_user.name } should be enabled"
      assert_no_difference('ProjectUser.count') do
        delete :destroy, id: @project_user
      end
      t_u = ProjectUser.find(@project_user.id)
      assert !t_u.is_enabled?, "#{ t_u.name } should not now be enabled"
    end
  end #Admin
end
