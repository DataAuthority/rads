class ProjectMembershipsController < ApplicationController
  load_resource :project
  load_and_authorize_resource :project_membership, through: :project

  def index
  end

  def show
  end

  def new
    @non_members = User.all.reject {|u| @project.is_member? u}
  end

  def create
    @non_members = User.all.reject {|u| @project.is_member? u}
    respond_to do |format|
      if @project_membership.save
        format.html { redirect_to [@project, @project_membership], notice: 'Project membership was successfully created.' }
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
      format.html { redirect_to project_project_memberships_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def project_membership_params
      params.require(:project_membership).permit(:user_id)
    end
end
