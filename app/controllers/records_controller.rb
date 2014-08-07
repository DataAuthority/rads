class RecordsController < ApplicationController
  load_and_authorize_resource except: [:index]
  before_action :authorize_download, only: [:show]
  around_action :audit_activity, only: [:create, :destroy]
  before_action :authorize_project_affiliation, only: [:create]

  def index
    unless current_user.nil?
      @record_creators = []
      @content_types = []
      Record.accessible_by(current_ability).each do |r|
        @record_creators << r.creator unless @record_creators.include? r.creator
        @content_types << r.content_content_type unless @content_types.include? r.content_content_type
      end
      @annotation_creators = Annotation.all.collect{|a| a.creator }.uniq
      @accessible_projects = current_user.projects
      # TODO allow record_filters in unauthenticated searches with limited parameters
      if params[:record_filter] || params[:record_filter_id]
        if params[:record_filter]
         @record_filter = current_user.record_filters.build(record_filter_params)
         if params[:remove_annotation_filters]
           @record_filter.annotation_filter_terms = AnnotationFilterTerm.none
         end
        else
          @record_filter = current_user.record_filters.find(params[:record_filter_id])
        end
        @records = @record_filter.query(Record.all).accessible_by(current_ability)
        if @record_filter.annotation_filter_terms.empty?
          @record_filter.annotation_filter_terms.build
        end
      else
        @record_filter = current_user.record_filters.build(record_created_by: current_user.id)
        @record_filter.annotation_filter_terms.build
        @records = current_user.records
      end
    end
    if @record_filter.project_affiliation_filter_term.nil?
      @record_filter.build_project_affiliation_filter_term
    end
    if params[:add_annotation_filter]
      @record_filter.annotation_filter_terms.build
    end

    @records = @records.order('records.created_at desc') if @records

    respond_to do |format|
      format.html do
        @records = @records.page(params[:page]).per_page(30) if @records 
      end
      format.json
    end
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
    @record.annotations.each do |a|
      a.creator_id = current_user.id
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
    @record.destroy_content
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
      params.require(:record).permit(:content,
                                     annotations_attributes: [:term, :context],
                                     project_affiliated_records_attributes: [:project_id]
                                    )
    end

    def record_filter_params
      permitted_params = [
        :name,
        :record_created_by,
        :is_destroyed,
        :record_created_on,
        :record_created_after,
        :record_created_before,
        :filename,
        :file_content_type,
        :file_size,
        :file_size_less_than,
        :file_size_greater_than,
        :file_md5hashsum,
        project_affiliation_filter_term_attributes: [:project_id],
        annotation_filter_terms_attributes: [:created_by, :term, :context]
      ]
      params.require(:record_filter).permit(permitted_params)
    end

    def authorize_download
      authorize! :download, @record if params[:download_content]
    end

    def authorize_project_affiliation
      params = record_params
      if params[:project_affiliated_records_attributes]
        params[:project_affiliated_records_attributes].each do |par|
          authorize! :affiliate_record_with, Project.find(par[:project_id])
        end
      end
    end
end
