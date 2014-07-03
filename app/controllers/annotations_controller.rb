class AnnotationsController < ApplicationController
  load_and_authorize_resource :annotation, only: [:destroy]
  load_resource :record, only: [:new, :create]
  load_and_authorize_resource :annotation, through: :record, only: [:new, :create]

  def index
    @annotations = Annotation.accessible_by(current_ability)
    if params[:creator_id]
      @annotations = @annotations.where(creator_id: params[:creator_id])
    end
    if params[:record_id]
      @annotations = @annotations.where(record_id: params[:record_id])
    end
    if params[:context]
      @annotations = @annotations.where(context: params[:context])
    end
    if params[:term]
      @annotations = @annotations.where(term: params[:term])
    end
  end

  def new
  end

  def create
    @annotation.creator_id = current_user.id
    respond_to do |format|
      if @annotation.save
        format.html { redirect_to annotations_url(record_id: @record.id), notice: 'Annotation was successfully created.' }
        format.json { render action: 'show', status: :created, location: @annotation }
      else
        format.html { render action: 'new' }
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @annotation.destroy
    respond_to do |format|
      format.html { redirect_to annotations_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def annotation_params
      params.require(:annotation).permit(:context, :term)
    end
end
