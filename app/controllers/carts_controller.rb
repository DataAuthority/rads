class CartsController < ApplicationController
  before_action :load_cart_records
  before_action :load_and_authorize_records, only: :update

  def show
    @cart_context = 'manage'
    @cart_errors = {}
    if flash[:cart_messages]
      @cart_messages = flash[:cart_messages]
    else
      @cart_messages = {}
    end

    if params[:cart_context]
      @cart_context = params[:cart_context]
    end
    @cart = Cart.new(params[:cart])
    @projects = current_user.projects
  end

  def update
    @cart_messages = {}
    if cart_params[:action] == 'destroy_records'
      @cart_context = 'manage'
      @records.each {|r| 
        if r.destroy_content
          @cart_messages[r.id] = 'record destroyed'
        end
      }
    elsif cart_params[:action] == 'affiliate_to_project'
      @cart_context = 'affiliate'
      @project_affiliated_records.each {|r| 
          if r.save
            @cart_messages[r.record_id] = "record affiliated with project #{ r.project }".html_safe
          end
        }
    elsif cart_params[:action] = 'create_record_annotation'
      @cart_context = 'annotate'
      @annotations.each {|a| 
        if a.save
          @cart_messages[a.record_id] = "record annotated with #{ a }".html_safe
        end
      }
    end

    respond_to do |format|
      if @cart_errors.empty?
        format.html { redirect_to cart_url(cart_context: @cart_context), flash: {cart_messages: @cart_messages } }
        format.json { head :no_content }
      else
        @cart = Cart.new(params[:cart])
        @projects = current_user.projects
        format.html { render action: 'show' }
        format.json { render json: @cart_errors, status: :unprocessable_entity }
      end
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
      params.require(:cart).permit(:action, :project_id, :term, :context)
    end

    def load_cart_records
      @cart_records = current_user.cart_records
    end

    def load_and_authorize_records
      @cart_errors = {}
      if cart_params[:action] == 'destroy_records'
        @records = []
        @cart_records.each do |cr|
          if cr.stored_record.is_destroyed?
            @cart_errors[cr.id] = 'this record is already destroyed'
          else
            if can? :destroy, cr.stored_record
              @records << cr.stored_record
            else
              @cart_errors[cr.id] = 'you are not allowed to destroy this record'
            end
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
            if par.valid?
              @project_affiliated_records << par
            else
              @cart_errors[cr.id] = "#{ par.errors.full_messages.join(' ') }"
            end
          end
        end
      elsif cart_params[:action] == 'annotate'
        @annotations = []
        @cart_records.each do |cr|
          if can? :show, cr.stored_record
            annotation = current_user.annotations.build(record_id: cr.stored_record.id, term: cart_params[:term], context: cart_params[:context])
            if annotation.valid?
              @annotations << annotation
            else
              @cart_errors[cr.id] = "#{ annotation.errors.full_messages.join(" ") }"
            end
          else
            @cart_errors[cr.id] = 'You cannot annotate this record'
          end
        end
      end
    end
end
