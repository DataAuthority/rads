class CoresController < ApplicationController
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
    @core.creator_id = current_user.id
    respond_to do |format|
      if @core.save
        format.html { redirect_to @core, notice: 'Core was successfully created.' }
        format.json { render action: 'show', status: :created, location: @core }
      else
        format.html { render action: 'new' }
        format.json { render json: @core.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @core.update(core_params)
        format.html { redirect_to @core, notice: 'Core was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @core.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def core_params
      params.require(:core).permit(:name, :description)
    end
end
