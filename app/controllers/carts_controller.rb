class CartsController < ApplicationController
  before_action :load_cart_records
  before_action :load_and_authorize_records, only: :update

  def show
  end

  def update
    @records.each do |r|
      r.destroy_content
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
      params.require(:cart).permit(:action)
    end

    def load_cart_records
      @cart_records = current_user.cart_records
    end

    def load_and_authorize_records
      @records = @cart_records.collect {|cr| cr.stored_record}
      @records.each do |r|
        if cart_params[:action] == 'destroy_records'
          authorize! :destroy, r
        end
      end
    end
end
