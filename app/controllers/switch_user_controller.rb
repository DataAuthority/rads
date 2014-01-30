class SwitchUserController < ApplicationController
  def switch_to
    session[:switch_to_user_id] = nil
    session[:switch_back_user_id] = nil
    target_user = User.find(params[:id])
    @current_ability = nil
    authorize! :switch_to, target_user
    session[:switch_back_user_id] = current_user.id
    session[:switch_to_user_id] = target_user.id
    if params[:target]
      redirect_to params[:target]
    else
      redirect_to root_path
    end
  end

  def destroy
    session[:switch_to_user_id] = nil
    session[:switch_back_user_id] = nil
    if params[:target]
      redirect_to params[:target]
    else
      redirect_to root_path
    end
  end
end
