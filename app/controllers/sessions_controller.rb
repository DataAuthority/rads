class SessionsController < ApplicationController
  skip_before_action :check_session, only: [:new, :create, :destroy]
  def new
    unless session_empty?
      redirect_to repository_users_url
      return
    end
    reset_session
    if params[:target]
      session[:redirect_on_return] = params[:target]
    else
      session[:redirect_on_return] = repository_users_url
    end
  end

  def check
    render text: "PASS"
  end

  def create
    redirect_on_return = session[:redirect_on_return]
    reset_shib_session
    load_shib_user
    if @shib_user.nil?
      session[:user_name] = request.env['omniauth.auth'][:info][:name]
      session[:user_email] = request.env['omniauth.auth'][:info][:email]
      session[:redirect_on_create] = redirect_on_return
    else
      @shib_user.register_login_client(request.env['HTTP_USER_AGENT'])
      @shib_user.save
    end
    redirect_to redirect_on_return
  end

  def destroy
    reset_session
    return_to = '?logoutWithoutPrompt=1&Submit=yes, log me out&returnto=%s' % params[:target]
    return_to_encoded = ERB::Util::url_encode( request = return_to )
    redirect_this_to = url_for("") + Rails.application.config.shibboleth_logout_url + return_to_encoded
    redirect_to redirect_this_to
  end

  private

  def reset_shib_session
    reset_session
    session[:uid] = request.env['omniauth.auth'][:uid]
    session[:provider] = request.env['omniauth.auth'][:provider]
    session[:shib_session_id] = request.env['HTTP_SHIB_SESSION_ID']
    session[:shib_session_index] = request.env['HTTP_SHIB_SESSION_INDEX']
    session[:created_at] = Time.now
  end

end
