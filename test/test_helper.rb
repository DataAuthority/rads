ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "paperclip/matchers"

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Hopefully a temporary fix in order to get shoulda syntax working.
  # Cause of issue is due to Shoulda adding the following to Test::Unit,
  # which has been been replaced by Minitest::Test::Unit in Rails 4.
  include Shoulda::Matchers::ActiveRecord
  extend Shoulda::Matchers::ActiveRecord
  include Shoulda::Matchers::ActiveModel
  extend Shoulda::Matchers::ActiveModel
  include Paperclip::Shoulda::Matchers
  extend Paperclip::Shoulda::Matchers

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Helpers for testing abilities 
  def allowed_abilities(user, object, actions)
      ability = Ability.new(user)
      actions.each do |action|
        assert ability.can?(action, object), "#{user.inspect}\n[ CANNOT! ] #{action}\n #{ object.inspect }"
      end
  end
  
  def denied_abilities(user, object, actions)
      ability = Ability.new(user)
      actions.each do |action|
        assert ability.cannot?(action, object), "#{user.inspect}\n [ CAN! ] #{action}\n #{ object.inspect }"
      end
  end

  def ignore_authorization(controller)
    ability = Object.new
    ability.extend(CanCan::Ability)
    controller.stubs(:current_ability).returns(ability)
    ability.can [:read, :new, :create, :edit, :update, :destroy], :all
  end

  def use_authorization(controller)
    controller.unstub(:current_ability)
  end

  def authenticate_existing_user(user, set_session = false)
    authenticate_any_user(user)
    @request.env['HTTP_UID'] = user.netid
    if set_session
      session[:shib_session_id] = @request.env['HTTP_SHIB_SESSION_ID']
      session[:shib_session_index] = @request.env['HTTP_SHIB_SESSION_INDEX']
      session[:created_at] = Time.now
    end
  end

  def authenticate_new_user(user)
    authenticate_any_user(user)
  end

  def authenticate_any_user(user)
    @request.env['HTTP_SHIB_SESSION_ID'] = 'asdf'
    @request.env['HTTP_SHIB_SESSION_INDEX'] = 'x1yaz344@'
    @request.env['HTTP_UID'] = user.netid
  end    

  # Common controller actions
  def self.should_not_get(action, path_override = {}, action_params = {})
    redirect_path = {controller: :sessions, action: :new}.merge(path_override)
    should "not get #{action}" do
      get action, action_params
      assert_redirected_to redirect_path.merge({:target => @request.original_url})
    end
  end

  # Audited activity testing
  def assert_audited_activity(current_user, authenticated_user, method, action, controller_name, &block)
    assert_difference('AuditedActivity.count') do
      block.call()
      # Test that the correct information was audited
      assert_not_nil assigns(:audited_activity)
      assert assigns(:audited_activity).valid?, "ERRORS #{ assigns(:audited_activity).errors.messages.inspect }"
      assert_equal current_user.id, assigns(:audited_activity).current_user_id
      assert_equal authenticated_user.id, assigns(:audited_activity).authenticated_user_id
      assert_equal controller_name, assigns(:audited_activity).controller_name
      assert_equal action, assigns(:audited_activity).action
      assert_equal method, assigns(:audited_activity).http_method
    end
  end
end
