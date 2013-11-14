class SessionsController < ApplicationController
  skip_before_action :check_session
  def new
    unless request.env['HTTP_UID'].nil? || request.env['HTTP_UID'].empty?
      redirect_to repository_users_url
      return
    end
    reset_session
    if params[:target]
      @redirect_target = params[:target]
    else
      @redirect_target = repository_users_url
    end
  end

  def check
    if session_valid(params[:target])
      render text: "PASS"
    end
  end

  def create
    reset_shib_session
    load_shib_user
    if shib_user.nil?
      session[:redirect_after_create] = params[:target]
      redirect_to new_repository_user_url
    else
      redirect_to params[:target]
    end
  end

  def destroy
    reset_session
    return_to = '?logoutWithoutPrompt=1&Submit=yes, log me out&returnto=%s' % params[:target]
    return_to_encoded = ERB::Util::url_encode( request = return_to )
    redirect_this_to = url_for("") + Rails.application.config.shibboleth_logout_url + return_to_encoded
    redirect_to redirect_this_to
  end
end
