class CartsController < ApplicationController
  def show
    @cart_records = current_user.cart_records
  end

  def update
    respond_to do |format|
      format.html { redirect_to cart_url }
      format.json { head :no_content }
    end
  end

  def destroy
    current_user.cart_records.destroy_all
    respond_to do |format|
      format.html { redirect_to cart_url }
      format.json { head :no_content }
    end
  end

  private
end
