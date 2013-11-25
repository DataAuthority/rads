class CoreMembershipsController < ApplicationController
  load_resource :core
  load_and_authorize_resource :core_membership, through: :core

  def index
  end

  def show
  end

  def new
    @non_members = RepositoryUser.all.reject {|u| @core.is_member? u}
  end

  def create
    @non_members = RepositoryUser.all.reject {|u| @core.is_member? u}
    respond_to do |format|
      if @core_membership.save
        format.html { redirect_to [@core, @core_membership], notice: 'Core membership was successfully created.' }
        format.json { render action: 'show', status: :created, location: @core_membership }
      else
        format.html { render action: 'new' }
        format.json { render json: @core_membership.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @core_membership.destroy
    respond_to do |format|
      format.html { redirect_to core_core_memberships_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def core_membership_params
      params.require(:core_membership).permit(:repository_user_id)
    end
end
