# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :shib_user, :puppet, :switch_to_users, :session_empty

  before_action :check_session
  before_action :redirect_disabled_users

  rescue_from ActiveRecord::RecordNotFound, :with => :missing_record
  rescue_from CanCan::AccessDenied, :with => :action_denied
  rescue_from ActionController::ParameterMissing, with: :access_denied

  def current_user
    puppet || shib_user
  end

  def switch_to_users
    switch_to_users = RepositoryUser.accessible_by(current_ability, :switch_to).where.not(id: current_user.id)
    switch_to_users = switch_to_users + CoreUser.accessible_by(current_ability, :switch_to)
    switch_to_users = switch_to_users + ProjectUser.accessible_by(current_ability, :switch_to)
  end

private
  def audit_activity
    @audited_activity = AuditedActivity.new({
      current_user_id: current_user.id,
      authenticated_user_id: shib_user.id,
      controller_name: controller_name,
      http_method: request.method.downcase,
      action: action_name,
      params: filter_audited_params(params).to_json
    })

    yield

    @audited_activity.record_id = @record.id if @record
    @audited_activity.save
  end

  def filter_audited_params(params)
    params
  end

  def check_session
    authenticated &&
    user_exists &&
    session_valid(url_for(params.merge(:only_path => false)))
  end

  def authenticated
    if session_empty?
      redirect_to sessions_new_path(target: url_for(params.merge(:only_path => false)))
      return
    end
    @user_authenticated = true
    return true
  end

  def user_exists
    load_shib_user
    if @shib_user.nil?
      session[:redirect_on_create] = url_for(params.merge(:only_path => false))
      redirect_to new_repository_user_path
      return
    end
    @user_exists = true
    return true
  end

  def session_valid(redirect_if_fail)
    if session[:provider] == 'shibboleth'
      if (request.env['HTTP_SHIB_SESSION_ID'] != session[:shib_session_id]) ||
          (request.env['HTTP_SHIB_SESSION_INDEX'] != session[:shib_session_index])
        reset_session
        session[:redirect_on_return] = redirect_if_fail
        @shib_user = nil
        redirect_to shibboleth_login_path
        return
      end
    end
    @session_valid = true
    return true
  end

  def load_shib_user
    user_netid = session[:uid]
    @shib_user = RepositoryUser.find_by(:netid => user_netid)
  end

  def shib_user
    @shib_user
  end

  def puppet
    if session[:switch_to_user_id]
      unless @puppet && @puppet.id == session[:switch_to_user_id]
        @puppet = User.find(session[:switch_to_user_id])
        @puppet.acting_on_behalf_of = session[:switch_back_user_id]
      end
    else
      @puppet = nil
    end
    @puppet
  end

  def redirect_disabled_users
    unless current_user.nil? || current_user.is_enabled?
      flash[:notice] = "You are not allowed to view that page until your account has been enabled."
      redirect_to current_user
    end
  end

  def session_empty?
    session[:uid].nil? || session[:uid].empty?
  end

  def action_denied
    logger.debug "ACTION DENIED!"
    flash[:alert] = 'You do not have access to the page you requested!.'
    redirect_to root_path()
  end

  def access_denied
    render file: "#{Rails.root}/public/403", formats: [:html], status: 403, layout: false
  end

  def not_found
    render file: "#{Rails.root}/public/404", formats: [:html], status: 404, layout: false
  end

  def missing_record
    render file: "#{Rails.root}/public/404", formats: [:html], status: 404, layout: false
  end
end
