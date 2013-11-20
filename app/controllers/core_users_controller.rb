class CoreUsersController < ApplicationController
  before_action :set_core_user, only: [:show, :edit, :update, :destroy]

  # GET /core_users
  # GET /core_users.json
  def index
    @core_users = CoreUser.all
  end

  # GET /core_users/1
  # GET /core_users/1.json
  def show
  end

  # GET /core_users/new
  def new
    @core_user = CoreUser.new
  end

  # GET /core_users/1/edit
  def edit
  end

  # POST /core_users
  # POST /core_users.json
  def create
    @core_user = CoreUser.new(core_user_params)

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

  # PATCH/PUT /core_users/1
  # PATCH/PUT /core_users/1.json
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

  # DELETE /core_users/1
  # DELETE /core_users/1.json
  def destroy
    @core_user.destroy
    respond_to do |format|
      format.html { redirect_to core_users_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_core_user
      @core_user = CoreUser.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def core_user_params
      params[:core_user]
    end
end
