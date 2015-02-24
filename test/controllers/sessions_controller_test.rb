require 'test_helper'

class SessionsControllerTest < ActionController::TestCase


  setup do
    @requested_target = 'https://some.other.url'
  end

  context 'new' do
    should 'redirect to repository_users if already logged in through shibboleth' do
      existing_user = users(:dl)
      authenticate_user(existing_user)
      get :new
      assert_redirected_to repository_users_path
    end

    should 'get new and set session[:redirect_on_return] when not already logged in' do
      session[:uid] = nil
      get :new, target: @requested_target
      assert_not_nil session[:redirect_on_return]
      assert_equal @requested_target, session[:redirect_on_return]
      assert_response :success
    end
  end

  context 'create' do

    should 'initialize new session, register user client login, and redirect to session[:redirect_on_return] for existing user' do
      existing_user = users(:dl)
      @request.env['omniauth.auth'] = {
        :uid => existing_user.netid,
        :provider => 'shibboleth'
      }
      session[:should_not_be] = 'should not be'
      session[:redirect_on_return] = @requested_target

      assert existing_user.last_login_client.nil?, 'last_login_client should be nil'
      assert existing_user.last_login_time.nil?, 'last_login_time should be nil'
      get :create
      assert_redirected_to @requested_target

      assert session[:should_not_be].nil?, 'session should have been reset'
      assert_equal existing_user.netid, session[:uid]
      assert_equal 'shibboleth', session[:provider]
      assert_equal @request.env['HTTP_SHIB_SESSION_ID'], session[:shib_session_id]
      assert_equal @request.env['HTTP_SHIB_SESSION_INDEX'], session[:shib_session_index]
      assert_not_nil session[:created_at]
      assert_not_nil assigns[:shib_user]
      assert_equal existing_user.netid, assigns[:shib_user].netid
      existing_user.reload
      assert !existing_user.last_login_client.nil?, 'last_login_client should not be nil after session created'
      assert !existing_user.last_login_time.nil?, 'last_login_time should not be nil after session is created'
      existing_user.last_login_time = nil
      existing_user.last_login_client = nil
      existing_user.save
    end

    should 'initialize new session, set session[:redirect_on_create] to session[:redirect_on_return] session[:user_name] and session[:user_email], and redirect_to session[:redirect_on_return] for new user' do
      @request.env['omniauth.auth'] = {
        :uid => 'foob003',
        :provider => 'shibboleth',
        :info => {
          :name => 'foob',
          :email => 'foob@baz.com'
        }
      }
      assert User.find_by(netid: @request.env['omniauth.auth'][:uid]).nil?, 'foob003 should not exist'
      session[:should_not_be] = 'should not be'
      session[:redirect_on_return] = @requested_target

      post :create
      assert_redirected_to @requested_target

      assert session[:should_not_be].nil?, 'session should have been reset'
      assert_equal @requested_target, session[:redirect_on_create]
      assert_equal @request.env['HTTP_SHIB_SESSION_ID'], session[:shib_session_id]
      assert_equal @request.env['HTTP_SHIB_SESSION_INDEX'], session[:shib_session_index]
      assert_not_nil session[:created_at]
      assert_equal @request.env['omniauth.auth'][:info][:name], session[:user_name]
      assert_equal @request.env['omniauth.auth'][:info][:email], session[:user_email]
    end
  end

  context 'check_session' do
    # check is a test session route that has application_controller.check_session as a before_action
    # and is used to test that the login control system for the rest of the application works
    # as expected.  Other controllers can demonstrate that the following instance variables are
    # true after a call to an access controlled method to demonstrate that the respective access test
    # method that is part of application_controller#check_session was run.
    #  user_authenticated
    #  user_exists
    #  session_valid
    should 'reset session and redirect to session_new_path if the user has not authenticated' do
      expected_redirect_to = sessions_new_path(target: check_url)
      get :check
      assert assigns(:user_authenticated).nil?, 'user_authenticated should be nil'
      assert_redirected_to expected_redirect_to
      assert session[:uid].nil?, "session[:uid] should not be reset"
      assert session[:shib_session_id].nil?, "session[:shib_session_id] should not be reset"
      assert session[:shib_session_index].nil?, "session[:shib_session_index] should not be reset"
      assert session[:created_at].nil?, "session[:created_at] should not be reset"
      assert assigns[:shib_user].nil?, 'should not have set @shib_user'
    end

    should 'set session[:redirect_on_create] and redirect to new_repository_user_url if the authenticated user does not yet exist' do
      new_user = RepositoryUser.new(email: 'floob3@baz.net', name: 'Jim floob')
      new_user.netid = 'floob123'
      authenticate_user(new_user)
      expected_redirect_to = new_repository_user_url
      get :check
      assert assigns(:user_authenticated), 'user_authenticated should be true'
      assert assigns(:user_exists).nil?, 'user_exists should be nil'
      assert_redirected_to expected_redirect_to
      assert_equal new_user.netid, session[:uid]
      assert_equal session[:redirect_on_create], check_url
    end

    should 'reset session, set session[:redirect_on_return], and redirect to the shib_login_url if the shib request environment differs from the session shib values' do
      existing_user = users(:dl)
      authenticate_user(existing_user)
      @request.env['HTTP_SHIB_SESSION_ID'] = 'fsda'
      @request.env['HTTP_SHIB_SESSION_INDEX'] = 'x1yaz344@'

      expected_redirect_to = shibboleth_login_url
      get :check
      assert assigns(:user_authenticated), 'user_authenticated should be true'
      assert assigns(:user_exists), 'user_exists should be true'
      assert assigns(:session_valid).nil?, 'session_valid should be nil'
      assert_redirected_to expected_redirect_to
      assert_equal check_url, session[:redirect_on_return]
      assert session[:uid].nil?, "session[:uid] should have been reset"
      assert session[:shib_session_id].nil?, "session[:shib_session_id] should have been reset"
      assert session[:shib_session_index].nil?, "session[:shib_session_index] should have been reset"
      assert session[:created_at].nil?, "session[:created_at] should have been reset"
      assert assigns[:shib_user].nil?, 'should not have set @shib_user'
    end

    should 'set @shib_user if authenticated user exists and shib request environment matches session shib values' do
      existing_user = users(:dl)
      session[:uid] = existing_user.netid
      session[:shib_session_id] = @request.env['HTTP_SHIB_SESSION_ID']
      session[:shib_session_index] = @request.env['HTTP_SHIB_SESSION_INDEX']

      get :check
      assert assigns(:user_authenticated), 'user_authenticated should be true'
      assert assigns(:user_exists), 'user_exists should be true'
      assert assigns(:session_valid), 'session_valid should be true'
      assert_response :success
      assert_not_nil assigns[:shib_user]
      assert_equal existing_user.netid, assigns[:shib_user].netid
    end
  end

  context 'destroy' do
    should 'reset the session and redirect to shib_logout_url with a return to params[:target]' do
      existing_user = users(:dl)
      session[:uid] = existing_user.netid
      session[:shib_session_id] = @request.env['HTTP_SHIB_SESSION_ID']
      session[:shib_session_index] = @request.env['HTTP_SHIB_SESSION_INDEX']
      @request.env['HTTP_UID'] = existing_user.netid

      return_to = '?logoutWithoutPrompt=1&Submit=yes, log me out&returnto=%s' % @requested_target
      return_to_encoded = ERB::Util::url_encode( request = return_to )
      expected_redirect_to = @controller.url_for("") + Rails.application.config.shibboleth_logout_url + return_to_encoded

      get :destroy, target: @requested_target
      assert session[:uid].nil?, "session[:uid] should have been reset"
      assert session[:shib_session_id].nil?, "session[:shib_session_id] should have been reset"
      assert session[:shib_session_index].nil?, "session[:shib_session_index] should have been reset"
      assert session[:created_at].nil?, "session[:created_at] should have been reset"
      assert assigns[:shib_user].nil?, 'should not have set @shib_user'
      assert_redirected_to expected_redirect_to
    end
  end
end
