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
end
