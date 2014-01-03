# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :shib_user, :puppet, :switch_to_users

  before_action :check_session
  before_action :redirect_disabled_users
  before_action do
    resource = controller_name.singularize.to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end

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
      params: params.to_json 
    })

    yield

    @audited_activity.record_id = @record.id if @record
    @audited_activity.save
  end

  def check_session
    authenticated && 
      session_created && 
      session_valid(url_for(params.merge(:only_path => false)))
  end

  def authenticated
    if request.env['HTTP_SHIB_SESSION_ID'].nil? || request.env['HTTP_SHIB_SESSION_ID'].empty?
      unless session_empty?
        flash[:alert] = 'You have been logged out'
      end
      redirect_to sessions_new_url(:target => url_for(params.merge(:only_path => false)))
      return
    end
    true
  end

  def session_created
    if session_empty?
      redirect_to sessions_create_url(:target => url_for(params.merge(:only_path => false)))
      return
    end
    true
  end

  def session_valid(redirect_if_fail)
    load_shib_user
    if (request.env['HTTP_SHIB_SESSION_ID'] != session[:shib_session_id]) ||     
        (request.env['HTTP_SHIB_SESSION_INDEX'] != session[:shib_session_index])
      reset_session
      @shib_user = nil
      redirect_url = (url_for("") + Rails.application.config.shibboleth_login_url + '?target=%s') % ERB::Util::url_encode( request = redirect_if_fail )
      redirect_to redirect_url
      return
    end
    return true
  end

  def load_shib_user
    user_netid = request.env['HTTP_UID']
    @shib_user = RepositoryUser.find_by(:netid => user_netid)
  end

  def shib_user
    @shib_user
  end

  def reset_shib_session
    reset_session
    session[:shib_session_id] = request.env['HTTP_SHIB_SESSION_ID']
    session[:shib_session_index] = request.env['HTTP_SHIB_SESSION_INDEX']
    session[:created_at] = Time.now
  end

  def puppet
    if session[:switch_to_user_id]
      unless @puppet && @puppet.id == session[:switch_to_user_id]
        @puppet = User.find(session[:switch_to_user_id])
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
    session[:shib_session_id].nil? || session[:shib_session_id].empty?
  end

  def action_denied
    flash[:alert] = 'You do not have access to the page you requested!.'
    redirect_to root_path()
  end

  def access_denied
    render file: "#{Rails.root}/public/403", formats: [:html], status: 403, layout: false
  end
end
