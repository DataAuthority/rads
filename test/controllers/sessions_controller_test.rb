require 'test_helper'

class SessionsControllerTest < ActionController::TestCase


  setup do
    @request.env['HTTP_SHIB_SESSION_ID'] = 'asdf'
    @request.env['HTTP_SHIB_SESSION_INDEX'] = 'x1yaz344@'
    @requested_target = 'https://some.other.url'
  end

  context 'new' do
    should 'redirect to repository_users if already logged in through shibboleth' do
      @request.env['HTTP_UID'] = 'foo003'
      get :new
      assert_redirected_to repository_users_path
    end

     should 'get new when not already logged in' do
      @request.env['HTTP_SHIB_SESSION_ID'] = nil
      @request.env['HTTP_SHIB_SESSION_INDEX'] = nil
      @request.env['HTTP_UID'] = nil
      get :new, target: @requested_target
      assert_response :success
    end
  end

  context 'create' do
    should 'initialize new session and redirect to params[:target] for existing user' do
      existing_user = users(:dl)
      @request.env['HTTP_UID'] = existing_user.netid
      session[:should_not_be] = 'should not be'

      get :create, target: @requested_target
      assert_redirected_to @requested_target

      assert session[:should_not_be].nil?, 'session should have been reset'
      assert_equal @request.env['HTTP_SHIB_SESSION_ID'], session[:shib_session_id]
      assert_equal @request.env['HTTP_SHIB_SESSION_INDEX'], session[:shib_session_index]
      assert_not_nil session[:created_at]
      assert_not_nil assigns[:shib_user]
      assert_equal existing_user.netid, assigns[:shib_user].netid
    end

    should 'initialize new session and redirect_to new_repository_user_path for new user' do
      @request.env['HTTP_UID'] = 'foob003'
      assert User.find_by(netid: @request.env['HTTP_UID']).nil?, 'foob003 should not exist'
      session[:should_not_be] = 'should not be'

      post :create, target: @requested_target
      assert_redirected_to new_repository_user_path

      assert session[:should_not_be].nil?, 'session should have been reset'
      assert_equal @requested_target, session[:redirect_after_create]
      assert_equal @request.env['HTTP_SHIB_SESSION_ID'], session[:shib_session_id]
      assert_equal @request.env['HTTP_SHIB_SESSION_INDEX'], session[:shib_session_index]
      assert_not_nil session[:created_at]
    end
  end

  context 'check' do
    should 'reset session and redirect to the shib_login_url if the shib request environment differs from the session shib values' do
      existing_user = users(:dl)
      session[:shib_session_id] = 'wxyz'
      session[:shib_session_index] = '@443zay1x'
      session[:created_at] = Time.now
      @request.env['HTTP_UID'] = existing_user.netid

      expected_redirect_to = (@controller.url_for("") + Rails.application.config.shibboleth_login_url + '?target=%s') % ERB::Util::url_encode( request = @requested_target )
      get :check, target: @requested_target
      assert_redirected_to expected_redirect_to
      assert session[:shib_session_id].nil?, "session[:shib_session_id] should have been reset"
      assert session[:shib_session_index].nil?, "session[:shib_session_index] should have been reset"
      assert session[:created_at].nil?, "session[:created_at] should have been reset"
      assert assigns[:shib_user].nil?, 'should not have set @shib_user'
    end

    should 'set @shib_user if shib request environment matches session shib values' do
      existing_user = users(:dl)
      session[:shib_session_id] = @request.env['HTTP_SHIB_SESSION_ID']
      session[:shib_session_index] = @request.env['HTTP_SHIB_SESSION_INDEX']
      @request.env['HTTP_UID'] = existing_user.netid

      get :check, target: @requested_target
      assert_response :success
      assert_not_nil assigns[:shib_user]
      assert_equal existing_user.netid, assigns[:shib_user].netid
    end
  end

  context 'destroy' do
    should 'reset the session and redirect to shib_logout_url with a return to params[:target]' do
      existing_user = users(:dl)
      session[:shib_session_id] = @request.env['HTTP_SHIB_SESSION_ID']
      session[:shib_session_index] = @request.env['HTTP_SHIB_SESSION_INDEX']
      @request.env['HTTP_UID'] = existing_user.netid

      return_to = '?logoutWithoutPrompt=1&Submit=yes, log me out&returnto=%s' % @requested_target
      return_to_encoded = ERB::Util::url_encode( request = return_to )
      expected_redirect_to = @controller.url_for("") + Rails.application.config.shibboleth_logout_url + return_to_encoded

      get :destroy, target: @requested_target
      assert session[:shib_session_id].nil?, "session[:shib_session_id] should have been reset"
      assert session[:shib_session_index].nil?, "session[:shib_session_index] should have been reset"
      assert session[:created_at].nil?, "session[:created_at] should have been reset"
      assert assigns[:shib_user].nil?, 'should not have set @shib_user'
      assert_redirected_to expected_redirect_to   
    end
  end

end
