class ProjectUsersController < ApplicationController
  load_and_authorize_resource

  # GET /project_users
  # GET /project_users.json
  def index
  end

  # GET /project_users/1
  # GET /project_users/1.json
  def show
  end

  # GET /project_users/new
  def new
  end

  # GET /project_users/1/edit
  def edit
  end

  # POST /project_users
  # POST /project_users.json
  def create
    respond_to do |format|
      if @project_user.save
        format.html { redirect_to @project_user, notice: 'Project user was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project_user }
      else
        format.html { render action: 'new' }
        format.json { render json: @project_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @project_user.update(project_user_params)
        format.html { redirect_to project_users_path, notice: 'Project user was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project_user.is_enabled = false
    @project_user.save
    respond_to do |format|
      format.html { redirect_to project_users_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def project_user_params
      if current_user.is_administrator?
        params.require(:project_user).permit(:is_enabled)
      end
    end
end
