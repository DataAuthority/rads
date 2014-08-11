class RecordFiltersController < ApplicationController
  load_and_authorize_resource
  def index
    @record_filters = current_user.record_filters.all.order('record_filters.created_at desc')
    @record_filters = @record_filters.page(params[:page]).per_page(30) if @record_filters 
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    @record_filter.user_id = current_user.id

    respond_to do |format|
      if @record_filter.save
        format.html { redirect_to record_filters_path, notice: 'Record filter was successfully created.' }
        format.json { render action: 'show', status: :created, location: @record_filter }
      else
        format.html { render action: 'new' }
        format.json { render json: @record_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @record_filter.update(record_filter_params)
        format.html { redirect_to @record_filter, notice: 'Record filter was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @record_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @record_filter.destroy
    respond_to do |format|
      format.html { redirect_to record_filters_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
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
        project_affiliation_filter_term_attributes: [:id, :project_id, :_destroy],
        annotation_filter_terms_attributes: [:id, :created_by, :term, :context, :_destroy]
      ]
      params.require(:record_filter).permit(permitted_params)
    end
end
