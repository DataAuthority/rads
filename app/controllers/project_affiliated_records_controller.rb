class ProjectAffiliatedRecordsController < ApplicationController
  load_resource :project
  load_and_authorize_resource :project_affiliated_record, through: :project

  def index
  end

  def show
  end

  def new
    @unaffiliated_records = current_user.records.reject {|r| @project.is_affiliated_record? r}
  end

  def edit
  end

  def create
    @unaffiliated_records = current_user.records.reject {|r| @project.is_affiliated_record? r}
    respond_to do |format|
      if @project_affiliated_record.save
        format.html { redirect_to @project, notice: 'Project affiliated record was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project_affiliated_record }
      else
        format.html { render action: 'new' }
        format.json { render json: @project_affiliated_record.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @project_affiliated_record.update(project_affiliated_record_params)
        format.html { redirect_to @project, notice: 'Project affiliated record was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project_affiliated_record.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project_affiliated_record.destroy
    respond_to do |format|
      format.html { redirect_to @project }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def project_affiliated_record_params
      params.require(:project_affiliated_record).permit(:record_id)
    end
end
