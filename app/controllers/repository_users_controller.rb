class RepositoryUsersController < ApplicationController
  skip_before_action :check_session, only: [:new, :create]
  load_and_authorize_resource
  skip_authorize_resource only: [:new, :create]
  skip_before_action :redirect_disabled_users, only: [:show]
  before_action :switch_disabled_users, only: [:show]
  before_action :prevent_dual_creation, only: [:new, :create]

  def index
  end

  def show
  end

  def new
    if authenticated && session_valid(url_for(params.merge(:only_path => false)))
      load_shib_user
      unless @shib_user.nil?
        redirect_to root_path
        return
      end
      @current_ability = nil
      authorize! :new, @repository_user
      @repository_user.name = session[:user_name]
      @repository_user.email = session[:user_email]
    end
  end

  def edit
  end

  def create
    if authenticated && session_valid(url_for(params.merge(:only_path => false)))
      load_shib_user
      unless @shib_user.nil?
        redirect_to root_path
        return
      end
      @current_ability = nil
      authorize! :create, @repository_user
      @repository_user.netid = session[:uid]
      @repository_user.is_enabled = true
      @repository_user.register_login_client(request.env['HTTP_USER_AGENT'])
      respond_to do |format|
        if @repository_user.save
          format.html { redirect_to @repository_user, notice: 'Repository user was successfully created.' }
          format.json { render action: 'show', status: :created, location: @repository_user }
        else
          format.html { render action: 'new' }
          format.json { render json: @repository_user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @repository_user.update(repository_user_params)
        format.html { redirect_to @repository_user, notice: 'Repository user was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @repository_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @repository_user.is_enabled = false
    @repository_user.save
    respond_to do |format|
      format.html { redirect_to repository_users_url }
      format.json { head :no_content }
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def repository_user_params
    permitted_params = [:name, :email]
    if current_user && current_user.is_administrator? && params[:id] != current_user.id.to_s
      permitted_params = [:is_enabled, :is_administrator]
    end
    params.require(:repository_user).permit(permitted_params)
  end

  def switch_disabled_users
    unless current_user.is_enabled?
      flash[:alert] = 'Your account is currently not enabled'
      unless params[:id] == current_user.id
        @repository_user = current_user
      end
    end
  end

  def prevent_dual_creation
    unless @shib_user.nil?
      redirect_to root_path
      return
    end
  end
end
