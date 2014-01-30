require 'test_helper'

class SwitchUserControllerTest < ActionController::TestCase

  context 'Not Authenticated' do
    should 'not get switch_user RepositoryUser' do
      RepositoryUser.all.each do |user|
        get :switch_to, id: user.id, target: @controller.url_for(user)
        assert_redirected_to sessions_new_url(:target => switch_to_url(id: user.id, target: @controller.url_for(user)))
      end
    end
    should 'not get switch_user CoreUser' do
      CoreUser.all.each do |user|
        get :switch_to, id: user.id, target: @controller.url_for(user)
        assert_redirected_to sessions_new_url(:target => switch_to_url(id: user.id, target: @controller.url_for(user)))
      end
    end
    should 'not get destroy' do
      get :destroy, target: repository_users_url
      assert_redirected_to sessions_new_url(:target => switch_back_url(target: repository_users_url))
    end
  end # Not Authenticated

  context 'Authenticated without session' do
    should 'not get switch_user RepositoryUser' do
      RepositoryUser.all.each do |ruser|
        authenticate_existing_user(ruser)
        RepositoryUser.where.not(id: ruser.id).each do |ouser|
          get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
          assert_redirected_to sessions_create_url(:target => switch_to_url(id: ouser.id, target: @controller.url_for(ouser)))
        end
      end
    end

    should 'not get switch_user CoreUser' do
      RepositoryUser.all.each do |ruser|
        authenticate_existing_user(ruser)
        CoreUser.all.each do |ouser|
          get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
          assert_redirected_to sessions_create_url(:target => switch_to_url(id: ouser.id, target: @controller.url_for(ouser)))
        end
      end
    end

    should 'not get destroy' do
      RepositoryUser.all.each do |ruser|
        authenticate_existing_user(ruser)
        get :destroy, target: repository_users_url
        assert_redirected_to sessions_create_url(:target => switch_back_url(target: repository_users_url))
      end
    end
  end #Authenticated without session

  context 'Disabled User' do
    should 'not get switch_user RepositoryUser' do
      RepositoryUser.all.each do |ruser|
        ruser.is_enabled = false
        ruser.save
        authenticate_existing_user(ruser, true)
        RepositoryUser.where.not(id: ruser.id).each do |ouser|
          get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
          assert_redirected_to repository_user_url(ruser)
          assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
          assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
        end
      end
    end

    should 'not get switch_user CoreUser' do
      RepositoryUser.all.each do |ruser|
        ruser.is_enabled = false
        ruser.save
        authenticate_existing_user(ruser, true)
        CoreUser.all.each do |ouser|
          get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
          assert_redirected_to repository_user_url(ruser)
          assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
          assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
        end
      end
    end

    should 'not get destroy' do
      RepositoryUser.all.each do |ruser|
        ruser.is_enabled = false
        ruser.save
        authenticate_existing_user(ruser, true)
        get :destroy, target: repository_users_url
        assert_redirected_to repository_user_url(ruser)
      end
    end
  end # Disabled User

  context 'NonAdmin' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should 'not get switch_user RepositoryUser' do
      RepositoryUser.where.not(id: @user.id).each do |ouser|
        get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
        assert_redirected_to root_path()
        assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
        assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
      end
    end

    should 'not get switch_user CoreUser for a Core that the user is not a member' do
      other_core = cores(:two)
      other_core_user = other_core.core_user
      assert !other_core.core_memberships.where(repository_user_id: @user.id).exists?, 'user should not be a member of the core'
      get :switch_to, id: other_core_user.id, target: @controller.url_for(other_core_user)
      assert_redirected_to root_path()
      assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
      assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
    end

    should 'get switch_user CoreUser for a Core that the user is a member' do
      core = cores(:one)
      core_user = core.core_user
      assert core.core_memberships.where(repository_user_id: @user.id).exists?, 'user should be a member of the core'
      get :switch_to, id: core_user.id
      assert_redirected_to root_url
      assert_not_nil session[:switch_to_user_id]
      assert_not_nil session[:switch_back_user_id]
      assert_equal core_user.id, session[:switch_to_user_id]
      assert_equal core_user.name, @controller.current_user.name
      assert_equal core_user.id, @controller.current_user.id
      assert_equal @user.id, session[:switch_back_user_id]
      assert_not_nil @controller.current_user.acting_on_behalf_of
      assert_equal @user.id, @controller.current_user.acting_on_behalf_of
      session[:switch_to_user_id] = nil
      session[:switch_back_user_id] = nil
    end

    should 'not get switch_user ProjectUser for a Project that the user is not a member' do
      other_project = projects(:two)
      other_project_user = other_project.project_user
      assert !other_project.project_memberships.where(user_id: @user.id).exists?, 'user should not be a member of the project'
      get :switch_to, id: other_project_user.id, target: @controller.url_for(other_project_user)
      assert_redirected_to root_path()
      assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
      assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
    end

    should 'get switch_user ProjectUser for a Project that the user is a member' do
      project = projects(:one)
      project_user = project.project_user
      assert project.project_memberships.where(user_id: @user.id).exists?, 'user should be a member of the project'
      get :switch_to, id: project_user.id, target: @controller.url_for(project_user)
      assert_redirected_to @controller.url_for(project_user)
      assert_not_nil session[:switch_to_user_id]
      assert_not_nil session[:switch_back_user_id]
      assert_equal project_user.id, session[:switch_to_user_id]
      assert_equal project_user.name, @controller.current_user.name
      assert_equal project_user.id, @controller.current_user.id
      assert_equal @user.id, session[:switch_back_user_id]
      assert_not_nil @controller.current_user.acting_on_behalf_of
      assert_equal @user.id, @controller.current_user.acting_on_behalf_of
      session[:switch_to_user_id] = nil
      session[:switch_back_user_id] = nil
    end

    should 'get destroy' do
      get :destroy
      assert_redirected_to root_url
      assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
      assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
      assert @controller.current_user.acting_on_behalf_of.nil?, 'current_user should not be acting on behalf of another user anymore'
    end
  end #NonAdmin

  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should 'get switch_user for a RepositoryUser' do
      RepositoryUser.where.not(id: @user.id).each do |ouser|
        get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
        assert_redirected_to @controller.url_for(ouser)
        assert_not_nil session[:switch_to_user_id]
        assert_not_nil session[:switch_back_user_id]
        assert_equal ouser.id, session[:switch_to_user_id]
        assert_equal ouser.name, @controller.current_user.name
        assert_equal ouser.id, @controller.current_user.id
        assert_equal @user.id, session[:switch_back_user_id]
        assert_not_nil @controller.current_user.acting_on_behalf_of
        assert_equal @user.id, @controller.current_user.acting_on_behalf_of
        session[:switch_to_user_id] = nil
        session[:switch_back_user_id] = nil
      end
    end

    should 'get switch_user for a CoreUser' do
      CoreUser.all.each do |ouser|
        get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
        assert_redirected_to @controller.url_for(ouser)
        assert_not_nil session[:switch_to_user_id]
        assert_not_nil session[:switch_back_user_id]
        assert_equal ouser.id, session[:switch_to_user_id]
        assert_equal ouser.name, @controller.current_user.name
        assert_equal ouser.id, @controller.current_user.id
        assert_equal @user.id, session[:switch_back_user_id]
        assert_not_nil @controller.current_user.acting_on_behalf_of
        assert_equal @user.id, @controller.current_user.acting_on_behalf_of
        session[:switch_to_user_id] = nil
        session[:switch_back_user_id] = nil
      end
    end

    should 'get switch_user for a ProjectUser' do
      ProjectUser.all.each do |ouser|
        get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
        assert_redirected_to @controller.url_for(ouser)
        assert_not_nil session[:switch_to_user_id]
        assert_not_nil session[:switch_back_user_id]
        assert_equal ouser.id, session[:switch_to_user_id]
        assert_equal ouser.name, @controller.current_user.name
        assert_equal ouser.id, @controller.current_user.id
        assert_equal @user.id, session[:switch_back_user_id]
        assert_not_nil @controller.current_user.acting_on_behalf_of
        assert_equal @user.id, @controller.current_user.acting_on_behalf_of
        session[:switch_to_user_id] = nil
        session[:switch_back_user_id] = nil
      end
    end

    should 'get destroy' do
      session[:switch_to_user_id] = users(:non_admin).id
      get :destroy, target: repository_users_url
      assert_redirected_to repository_users_url
      assert session[:switch_to_user_id].nil?, 'switch_to_user_id should not be in the session after destroy'
      assert session[:switch_back_user_id].nil?, 'switch_back_user_id should not be in the session after destroy'
      assert_equal @user.id, @controller.current_user.id
      assert @controller.current_user.acting_on_behalf_of.nil?, 'current user should not be acting_on_bahalf of another user'
    end
  end # Admin

end

