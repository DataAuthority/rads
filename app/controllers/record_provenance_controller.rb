class RecordProvenanceController < ApplicationController
  skip_before_action :check_session
  def show
    if params[:record_id]
      @record = Record.find(params[:record_id])
    elsif params[:md5]
      @record = Record.find_by_md5(params[:md5]).first
    else
      access_denied && return
    end
    @rendered_users = {}
    @rendered_cores = {}
    @rendered_projects = {}
    respond_to do |format|
      format.xml
    end
  end
end
