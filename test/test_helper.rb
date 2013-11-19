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
  def self.should_not_get_index(path_override = {})
    redirect_path = {controller: :sessions, action: :new}.merge(path_override)
    should "not get index" do
      get :index
      assert_redirected_to redirect_path.merge({:target => @request.original_url})
    end
  end

  def self.should_not_get_new(path_override = {})
    redirect_path = {controller: :sessions, action: :new}.merge(path_override)
    should "not get new" do
      get :new
      assert_redirected_to redirect_path.merge({:target => @request.original_url})
    end
  end
end
