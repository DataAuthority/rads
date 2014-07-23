class CartRecordsController < ApplicationController
  load_and_authorize_resource :except => [:empty]

  def create
    @cart_record.user_id = current_user.id
    respond_to do |format|
      if @cart_record.save
        format.html { redirect_to cart_url, notice: 'Cart record was successfully created.' }
        format.json { render json: {message: "record #{ @cart_record.record_id } added"} }
      else
        format.html { redirect_to cart_url, alert: 'Cart record was not successfully created.' }
        format.json { render json: @cart_record.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @cart_record.destroy
    respond_to do |format|
      format.html { redirect_to cart_url }
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def cart_record_params
      params.require(:cart_record).permit(:record_id)
    end
end
