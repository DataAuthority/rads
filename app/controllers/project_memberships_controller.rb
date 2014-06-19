class ProjectMembershipsController < ApplicationController
  load_resource :project
  load_and_authorize_resource :project_membership, through: :project
  before_action :check_administrator, only: [:update]

  def index
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @project_membership.update(project_membership_params)
        format.html { redirect_to @project, notice: 'ProjectMembership was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def new
    @non_members = User.all.reject {|u| @project.is_member? u}
  end

  def create
    @non_members = User.all.reject {|u| @project.is_member? u}
    respond_to do |format|
      if @project_membership.save
        format.html { redirect_to @project, notice: 'Project membership was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project_membership }
      else
        format.html { render action: 'new' }
        format.json { render json: @project_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project_membership.destroy
    respond_to do |format|
      format.html { redirect_to @project }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def project_membership_params
      params.require(:project_membership).permit(:user_id, :is_data_consumer, :is_data_manager, :is_data_producer, :is_administrator)
    end

    def check_administrator
      if project_membership_params[:is_administrator]
        authorize! :create, ProjectMembership.new(user_id: @project_membership.user_id, project_id: @project.id, is_administrator: project_membership_params[:is_administrator])
      end
    end
end
