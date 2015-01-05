require 'test_helper'

class CoreUsersControllerTest < ActionController::TestCase
  setup do
    @core = cores(:one)
    @core_user = @core.core_user
    @other_core = cores(:two)
    @other_core_user = @other_core.core_user
  end

  context 'CoreUser' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
      session[:switch_to_user_id] = @core_user.id
    end

    should 'not get index' do
      get :index
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should 'not update CoreUser' do
      @other_core_user.is_enabled = false
      @other_core_user.save
      assert !@other_core_user.is_enabled?, 'core_user should not be enabled'
      patch :update, id: @other_core_user, core_user: {is_enabled: true}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_u = CoreUser.find(@other_core_user.id)
      assert !t_u.is_enabled?, 'core_user should still not be enabled'
    end

    should 'not destroy any CoreUser' do
      CoreUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('CoreUser.count') do
          delete :destroy, id: cu
          assert_access_controlled_action
          assert_redirected_to root_path()
        end
        t_u = CoreUser.find(cu.id)
        assert t_u.is_enabled?, "#{ t_u.name } should still be enabled"
      end
    end
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
    end

    should 'not get index' do
      get :index
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should 'not update CoreUser' do
      @other_core_user.is_enabled = false
      @other_core_user.save
      assert !@other_core_user.is_enabled?, 'core_user should not be enabled'
      patch :update, id: @other_core_user, core_user: {is_enabled: true}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_u = CoreUser.find(@other_core_user.id)
      assert !t_u.is_enabled?, 'core_user should still not be enabled'
    end

    should 'not destroy any CoreUser' do
      CoreUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('CoreUser.count') do
          delete :destroy, id: cu
          assert_access_controlled_action
          assert_redirected_to root_path()
        end
        t_u = CoreUser.find(cu.id)
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

    should 'not update CoreUser' do
      @core_user.is_enabled = false
      @core_user.save
      assert !@core_user.is_enabled?, 'core_user should be enabled'
      patch :update, id: @core_user, core_user: {is_enabled: true}
      assert_access_controlled_action
      assert_redirected_to root_path()
      t_u = CoreUser.find(@core_user.id)
      assert !t_u.is_enabled?, 'core_user should still not be enabled'
    end

    should 'not destroy any CoreUser' do
      CoreUser.all.each do |cu|
        assert cu.is_enabled?, "#{ cu.name } should be enabled"
        assert_no_difference('CoreUser.count') do
          delete :destroy, id: cu
          assert_access_controlled_action
          assert_redirected_to root_path()
        end
        t_u = CoreUser.find(cu.id)
        assert t_u.is_enabled?, "#{ t_u.name } should still be enabled"
      end
    end
  end #NonAdmin

  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_user(@user)
    end

    should 'get index with all CoreUsers' do
      get :index
      assert_access_controlled_action
      assert_response :success
      assert_not_nil assigns(:core_users)
      count = assigns(:core_users).count
      assert count > 0, 'there should be some core_users'
      assert_equal CoreUser.count, count
    end

    should 'update CoreUser to enable them' do
      @core_user.is_enabled = false
      @core_user.save
      assert !@core_user.is_enabled?, 'core_user should be enabled'
      patch :update, id: @core_user, core_user: {is_enabled: true}
      assert_access_controlled_action
      t_u = CoreUser.find(@core_user.id)
      assert t_u.is_enabled?, 'core_user should still now be enabled'
    end

    should 'destroy any CoreUser by disabling' do
      assert @core_user.is_enabled?, "#{ @core_user.name } should be enabled"
      assert_no_difference('CoreUser.count') do
        delete :destroy, id: @core_user
        assert_access_controlled_action
      end
      t_u = CoreUser.find(@core_user.id)
      assert !t_u.is_enabled?, "#{ t_u.name } should not now be enabled"
    end
  end #Admin
end
