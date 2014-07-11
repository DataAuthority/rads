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
      @cart_errors = {}
      if cart_params[:action] == 'destroy_records'
        @records = []
        @cart_records.each do |cr|
          if can? :destroy, cr.stored_record
            @records << cr.stored_record
          else
            @cart_errors[cr.id] = 'you are not allowed to destroy this record'
          end
        end
      elsif cart_params[:action] == 'affiliate_to_project'
        @project_affiliated_records = []
        @cart_records.each do |cr|
          par =  ProjectAffiliatedRecord.new(record_id: cr.stored_record.id, project_id: cart_params[:project_id])
          if cannot? :affiliate, par.affiliated_record
            @cart_errors[cr.id] = 'You are not allowed to affiliate this record with projects'
          elsif cannot? :create, par
            @cart_errors[cr.id] = 'You are not allowed to affiliate records with this project'
          else
            @project_affiliated_records << par
          end
        end
      elsif cart_params[:action] == 'create_record_annotation'
      end
    end
end
