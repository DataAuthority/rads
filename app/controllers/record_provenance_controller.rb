class RecordProvenanceController < ApplicationController
  skip_before_action :check_session
  def show
    if params[:record_id]
      @records = Record.where(id: params[:record_id])
    elsif params[:md5]
      @records = Record.find_by_md5(params[:md5])
    end

    if @records.nil? || (@records.count < 1)
      not_found && return 
    end
    
    @rendered_users = {}
    @rendered_cores = {}
    @rendered_projects = {}
    respond_to do |format|
      format.xml
    end
  end
end
