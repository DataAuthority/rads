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
    user_information = "#{user.inspect}"
    if user && user.acting_on_behalf_of
      user_information = "#{ user_information } acting on behalf of #{ user.acting_on_behalf_of }"
    end
    actions.each do |action|
      assert ability.can?(action, object), "#{user_information}\n[ CANNOT! ] #{action}\n #{ object.inspect }"
    end
  end

  def denied_abilities(user, object, actions)
    ability = Ability.new(user)
    user_information = "#{user.inspect}"
    if user && user.acting_on_behalf_of
      user_information = "#{ user_information } acting on behalf of #{ user.acting_on_behalf_of }"
    end
    actions.each do |action|
      assert ability.cannot?(action, object), "#{user_information}\n [ CAN! ] #{action}\n #{ object.inspect }"
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

  def authenticate_user(user)
    session[:uid] = user.netid
    session[:provider] = 'shibboleth'
    session[:shib_session_id] = request.env['HTTP_SHIB_SESSION_ID'] = 'asdf'
    session[:shib_session_index] = request.env['HTTP_SHIB_SESSION_INDEX'] = 'x1yaz344@'
    session[:created_at] = Time.now
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

  # these instance varaibles are set within the 3 methods that application_controller#check_session
  # calls to test a users authenticity, existence, and session validity before calling access controlled actions
  def assert_access_controlled_action
    assert assigns(:user_authenticated), 'user should have been authenticated'
    assert assigns(:user_exists), 'user existence should have been tested'
    assert assigns(:session_valid), 'user session validity should have been tested'
  end

  def self.should_respond_to(method)
    should "respond to #{method}" do
      assert_respond_to subject, method
    end
  end

  def self.class_should_respond_to(method)
    should "respond to class #{method}" do
      assert_respond_to subject.class, method
    end
  end
end
