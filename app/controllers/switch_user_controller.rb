class SwitchUserController < ApplicationController
  def switch_to
    session[:switch_to_user_id] = nil
    session[:switch_back_user_id] = nil
    target_user = User.find(params[:id])
    @current_ability = nil
    authorize! :switch_to, target_user
    session[:switch_back_user_id] = current_user.id
    session[:switch_to_user_id] = target_user.id
    redirect_to params[:target]
  end

  def destroy
    session[:switch_to_user_id] = nil
    session[:switch_back_user_id] = nil
    redirect_to params[:target]
  end
end
