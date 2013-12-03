require 'test_helper'

class UserTest < ActiveSupport::TestCase
  should have_many :records
  should have_many :project_memberships
  should have_many(:projects).through(:project_memberships)

  should 'have a name' do
    assert_respond_to User.new, 'name'
  end

  should 'have storage_path' do
    @new_user = User.new(name: 'new_user')
    assert @new_user.id.nil?, 'id should be nil before save'
    assert @new_user.storage_path.nil?, 'storage_path should be nil if the id is nil'

    @new_user.save
    assert_respond_to @new_user, 'storage_path'
    assert_not_nil @new_user.storage_path
    assert_equal "#{ Rails.application.config.primary_storage_root }/#{ @new_user.id }", @new_user.storage_path
  end

  should 'have is_enabled' do
    assert_respond_to User.new, 'is_enabled'
    assert_respond_to User.new, 'is_enabled?'

    enabled_user = users('enabled')
    assert enabled_user.is_enabled?, 'dl should be enabled'
    disabled_user = users('disabled')
    assert !disabled_user.is_enabled?, 'disabled_user should be disabled'
  end

  should 'support is_administrator?' do
    @admin_user = users(:admin)
    @non_admin_user = users(:non_admin)
    assert_respond_to @admin_user, 'is_administrator?'
    assert_respond_to @non_admin_user, 'is_administrator?'

    assert @admin_user.is_administrator?, "#{ @admin_user } should be an administrator"
    assert !@non_admin_user.is_administrator?, "#{ @non_admin_user } should not be an administrator"
  end

end
