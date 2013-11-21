class CoreUsersController < ApplicationController
  load_and_authorize_resource

  # GET /core_users
  # GET /core_users.json
  def index
  end

  # GET /core_users/1
  # GET /core_users/1.json
  def show
  end

  # GET /core_users/new
  def new
  end

  # GET /core_users/1/edit
  def edit
  end

  # POST /core_users
  # POST /core_users.json
  def create
    respond_to do |format|
      if @core_user.save
        format.html { redirect_to @core_user, notice: 'Core user was successfully created.' }
        format.json { render action: 'show', status: :created, location: @core_user }
      else
        format.html { render action: 'new' }
        format.json { render json: @core_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @core_user.update(core_user_params)
        format.html { redirect_to @core_user, notice: 'Core user was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @core_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @core_user.is_enabled = false
    @core_user.save
    respond_to do |format|
      format.html { redirect_to core_users_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def core_user_params
      if current_user.is_administrator?
        params.require(:core_user).permit(:is_enabled)
      end
    end
end
