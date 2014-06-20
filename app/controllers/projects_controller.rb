class ProjectsController < ApplicationController
  load_and_authorize_resource
  before_action :authorize_update_attributes, only: [:update]
  before_action :authorize_affiliated_records, only: [:update, :create]
  before_action :authorize_project_memberships, only: [:update, :create]

  def index
  end

  def show
    @project_affiliated_records = @project.project_affiliated_records
    @project_memberships = @project.project_memberships
  end

  def new
  end

  def edit
  end

  def create
    @project.creator_id = current_user.id
    @project.project_memberships.build( user_id: current_user.id, is_administrator: true, is_data_producer: true, is_data_consumer: true, is_data_manager: true )
    @project.build_project_user(name: "Project #{ @project.name } User", is_enabled: true)
    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project }
      else
        format.html { render action: 'new' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      permitted_params = [
        :name,
        :description,
        project_affiliated_records_attributes: [:id, :_destroy, :record_id],
        project_memberships_attributes: [:id, :_destroy, :user_id]
      ]
      params.require(:project).permit(permitted_params)
    end

    def authorize_project_memberships
      params = project_params
      if params[:project_memberships_attributes]
        params[:project_memberships_attributes].each do |par|
          if @project.id.nil?
            @project.creator_id = current_user.id
            authorize! :create, ProjectMembership.new(par)
          else
            if par[:_destroy]
              authorize! :destroy, @project.project_memberships.find(par[:id])
            else
              authorize! :create, ProjectMembership.new(par.merge(:project_id => @project.id))
            end
          end
        end
      end
    end

    def authorize_affiliated_records
      params = project_params
      if params[:project_affiliated_records_attributes]
        params[:project_affiliated_records_attributes].each do |par|
          if @project.id.nil?
            @project.creator_id = current_user.id
            authorize! :affiliate, Record.find(par[:record_id])
          else
            if par[:_destroy]
              authorize! :destroy, @project.project_affiliated_records.find(par[:id])
            else
              authorize! :create, ProjectAffiliatedRecord.new(par.merge(:project_id => @project.id))
            end
          end
        end
      end
    end

    def authorize_update_attributes
      params = project_params
      if (project_params[:name] && project_params[:name] != @project.name) ||
      (project_params[:description] && project_params[:description] != @project.description)
        authorize! :update_attributes, @project
      end
    end
end
