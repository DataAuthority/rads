class RecordProvenanceController < ApplicationController
  skip_before_action :check_session
  def show
    if params[:record_id]
      @records = Record.where(id: params[:record_id])
    elsif (params[:md5] && params[:md5].length > 0) || (params[:filename] && params[:filename].length > 0)
      @records = Record.all
      if params[:md5] && params[:md5].length > 0
        @records = @records.find_by_md5(params[:md5])
      end
      if params[:filename] && params[:filename].length > 0
        @records = @records.where(content_file_name: params[:filename])
      end
    else
      @records = nil
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
