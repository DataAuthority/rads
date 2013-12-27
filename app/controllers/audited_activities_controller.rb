class AuditedActivitiesController < ApplicationController
  load_and_authorize_resource

  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    respond_to do |format|
      if @audited_activity.save
        format.html { redirect_to @audited_activity, notice: 'Audited activity was successfully created.' }
        format.json { render action: 'show', status: :created, location: @audited_activity }
      else
        format.html { render action: 'new' }
        format.json { render json: @audited_activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @audited_activity.update(audited_activity_params)
        format.html { redirect_to @audited_activity, notice: 'Audited activity was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @audited_activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @audited_activity.destroy
    respond_to do |format|
      format.html { redirect_to audited_activities_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def audited_activity_params
      params.require(:audited_activity).permit(:authenticated_user_id, :current_user_id, :controller_name, :http_method, :action, :params, :record_id)
    end
end
