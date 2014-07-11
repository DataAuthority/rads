class CartsController < ApplicationController
  before_action :load_cart_records
  before_action :load_and_authorize_records, only: :update

  def show
    @cart = Cart.new(params[:cart])
    @projects = current_user.projects
  end

  def update
    if cart_params[:action] == 'destroy_records'
      @records.each {|r| r.destroy_content}
    elsif cart_params[:action] == 'affiliate_to_project'
      @project_affiliated_records.each {|r| r.save}
    end
    respond_to do |format|
      format.html { redirect_to cart_url }
      format.json { head :no_content }
    end
  end

  def destroy
    @cart_records.destroy_all
    respond_to do |format|
      format.html { redirect_to cart_url }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def cart_params
      params.require(:cart).permit(:action, :project_id)
    end

    def load_cart_records
      @cart_records = current_user.cart_records
    end

    def load_and_authorize_records
      @records = @cart_records.collect {|cr| cr.stored_record}
      if cart_params[:action] == 'destroy_records'
        @records.each {|r| authorize! :destroy, r}
      elsif cart_params[:action] == 'affiliate_to_project'
        @project_affiliated_records = @records.collect {|r| ProjectAffiliatedRecord.new(record_id: r.id, project_id: cart_params[:project_id])}
        @project_affiliated_records.each {|r| 
            authorize! :affiliate, r.affiliated_record
            authorize! :create, r
        }
      elsif cart_params[:action] == 'create_record_annotation'
      end
    end
end
