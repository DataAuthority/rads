require 'test_helper'

class AuditedActivitiesControllerTest < ActionController::TestCase
  setup do
    @audited_activity = audited_activities(:one)
  end

  should 'not have destroy route' do
    assert_raises(ActionController::UrlGenerationError) {
      delete :destroy, id: @patient
    }
  end

  should 'not have new route' do
    assert_raises(ActionController::UrlGenerationError) {
      get :new
    }
  end

  should 'not have create route' do
    assert_raises(ActionController::UrlGenerationError) {
      post :create, audited_activity: { action: @audited_activity.action, authenticated_user_id: @audited_activity.authenticated_user_id, controller_name: @audited_activity.controller_name, current_user_id: @audited_activity.current_user_id, http_method: @audited_activity.http_method, params: @audited_activity.params, record_id: @audited_activity.record_id }
    }
  end

  should 'not have edit route' do
    assert_raises(ActionController::UrlGenerationError) {
      get :edit, id: @audited_activity
    }
  end

  should 'not have update route' do
    assert_raises(ActionController::UrlGenerationError) {
      patch :update, id: @audited_activity, audited_activity: { action: @audited_activity.action, authenticated_user_id: @audited_activity.authenticated_user_id, controller_name: @audited_activity.controller_name, current_user_id: @audited_activity.current_user_id, http_method: @audited_activity.http_method, params: @audited_activity.params, record_id: @audited_activity.record_id }
    }
  end

  should 'not have destroy route' do
    assert_raises(ActionController::UrlGenerationError) {
      delete :destroy, id: @audited_activity
    }
  end

  context 'Not Authenticated' do
    should_not_get :index

    should "not show audited_activity" do
      get :show, id: @audited_activity
      assert_redirected_to sessions_new_url(:target => audited_activity_url(@audited_activity))
    end
  end

  context 'Non Admin' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should 'not get index' do
      get :index
      assert_redirected_to root_path()
    end

    should 'not get show' do
      get :show, id: @audited_activity
      assert_redirected_to root_path()
    end
  end #Non Admin

  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should 'get index' do
      get :index
      assert_response :success
    end

    should 'get show with record_id' do
      @audited_activity.record_id = Record.first.id
      @audited_activity.save
      get :show, id: @audited_activity
      assert_response :success
      assert_not_nil assigns(:audited_activity)
      assert_not_nil assigns(:record)
      assert_equal @audited_activity.id, assigns(:audited_activity).id
    end

    should 'get show without record_id' do
      get :show, id: @audited_activity
      assert_response :success
      assert_not_nil assigns(:audited_activity)
      assert_nil assigns(:record)
      assert_equal @audited_activity.id, assigns(:audited_activity).id
    end
  end #Admin
end
