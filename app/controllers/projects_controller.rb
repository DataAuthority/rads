class ProjectsController < ApplicationController
  load_and_authorize_resource
  before_action :authorize_affiliated_records, only: [:update, :create]
  before_action :authorize_project_memberships, only: [:update, :create]
  before_action :authorize_update_attributes, only: [:update]

  def index
  end

  def show
    @project_affiliated_records = @project.project_affiliated_records
    @project_memberships = @project.project_memberships
  end

  def new
    @unaffiliated_records = current_user.records
    @unaffiliated_records.each do |record|
      @project.project_affiliated_records.build(record_id: record.id)
    end

    @potential_members = User.all - [current_user]
    @potential_members.each do |user|
      @project.project_memberships.build(user_id: user.id)
    end
  end

  def edit
    @unaffiliated_records = current_user.records.reject {|r| @project.is_affiliated_record? r}
    @unaffiliated_records.each do |record|
      @project.project_affiliated_records.build(record_id: record.id)
    end

    @potential_members = User.all.reject {|u| @project.is_member? u}
    @potential_members.each do |user|
      @project.project_memberships.build(user_id: user.id)
    end
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
        project_affiliated_records_attributes: [:id, :_destroy, :record_id],
        project_memberships_attributes: [:id, :_destroy, :user_id]
      ]
      if current_user.type == 'RepositoryUser'
        permitted_params = [:name, :description] + permitted_params
      end
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
            authorize! :create, ProjectMembership.new(par.merge(:project_id => @project.id))
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
          authorize! :create, ProjectAffiliatedRecord.new(par.merge(:project_id => @project.id))
        end
      end
    end
  end

  def authorize_update_attributes
    if @project.name_changed? || @project.description_changed?
      authorize! :update_attributes, @project
    end
  end
end
