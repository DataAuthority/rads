class RepositoryUsersController < ApplicationController
  skip_before_action :check_session, only: [:new, :create]
  before_action :authenticated, only: [:new, :create]
  load_and_authorize_resource
  skip_authorize_resource only: [:new, :create]
  skip_before_action :redirect_disabled_users, only: [:show]
  before_action :switch_disabled_users, only: [:show]

  def index
  end

  def show
  end

  def new
    reset_shib_session
    load_shib_user
    @current_ability = nil
    authorize! :new, @repository_user
    @repository_user.name = request.env['HTTP_DISPLAYNAME']
    @repository_user.email = request.env['HTTP_MAIL']
  end

  def edit
  end

  def create
    reset_shib_session
    if session_valid(url_for(params.merge(:only_path => false)))
      @current_ability = nil
      authorize! :create, @repository_user
      @repository_user.netid = request.env['HTTP_UID']
      @repository_user.is_enabled = true
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
      if @repository_user.update(params[:repository_user])
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
end
