class RecordsController < ApplicationController
  skip_before_action :check_session, only: [:index]
  load_and_authorize_resource except: [:index]
  around_action :audit_activity, only: [:create, :destroy]

  def index
    if params[:md5]
      @records = Record.find_by_md5(params[:md5]).select(:content_fingerprint, :created_at)
      @redirect_target = records_url
    else
      check_session

      unless current_user.nil?
        if params[:affiliated_with_project]
          @project = Project.find(params[:affiliated_with_project])
          if @project.is_member? current_user
            @records = @project.records
          else
            @records = current_user.records
          end
        else
          @records = current_user.records
        end
      end
    end

    @records = @records.order('created_at desc') if @records
  end

  def show
    if params[:download_content]
      if @record.content?
        send_file @record.content.path, type: @record.content_content_type, filename: @record.content_file_name
      end
    else
      respond_to do |format|
        format.html # show.html.erb
        format.json #show.json.jbuilder
      end
    end
  end

  def new
    @record.project_affiliated_records.build unless current_user.projects.empty?
  end

  def create
    @record.creator_id = current_user.id
    if current_user.type == 'ProjectUser'
      @record.project_affiliated_records.build(project_id: current_user.project_id)
    end
    respond_to do |format|
      if @record.save
        format.html { redirect_to @record, notice: 'Record was successfully created.' }
        format.json { render action: 'show', status: :created, location: @record }
      else
        format.html { render action: 'new' }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    File.delete(@record.content.path)
    @record.is_destroyed = true
    @record.save
    respond_to do |format|
      format.html { redirect_to records_url }
      format.json { head :no_content }
    end
  end

  private

    def filter_audited_params(params)
      new_params = params.clone
      if new_params[:record]
        if new_params[:record][:content]
          new_params[:record][:content] = {
            content_type: params[:record][:content].content_type,
            original_filename: params[:record][:content].original_filename
          }
        end
      end
      new_params
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def record_params
      params.require(:record).permit(:content, project_affiliated_records_attributes: [:project_id])
    end
end
