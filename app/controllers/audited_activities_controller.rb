class AuditedActivitiesController < ApplicationController
  before_action :set_audited_activity, only: [:show, :edit, :update, :destroy]

  # GET /audited_activities
  # GET /audited_activities.json
  def index
    @audited_activities = AuditedActivity.all
  end

  # GET /audited_activities/1
  # GET /audited_activities/1.json
  def show
  end

  # GET /audited_activities/new
  def new
    @audited_activity = AuditedActivity.new
  end

  # GET /audited_activities/1/edit
  def edit
  end

  # POST /audited_activities
  # POST /audited_activities.json
  def create
    @audited_activity = AuditedActivity.new(audited_activity_params)

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

  # PATCH/PUT /audited_activities/1
  # PATCH/PUT /audited_activities/1.json
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

  # DELETE /audited_activities/1
  # DELETE /audited_activities/1.json
  def destroy
    @audited_activity.destroy
    respond_to do |format|
      format.html { redirect_to audited_activities_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_audited_activity
      @audited_activity = AuditedActivity.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def audited_activity_params
      params.require(:audited_activity).permit(:authenticated_user_id, :current_user_id, :controller_name, :http_method, :action, :params, :record_id)
    end
end
