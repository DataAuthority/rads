require 'test_helper'

class CoreUserTest < ActiveSupport::TestCase
   should belong_to :core
   should validate_presence_of :core_id

  # ability test
  context 'nil user' do
    setup do
      @core_user = users(:core_user)
    end

    should 'pass ability profile' do
      denied_abilities(nil, @core_user, [:index, :destroy, :switch_to])
    end
  end #nil user

  context 'admin user' do
    setup do
      @user = users(:admin)
      @core_user = users(:core_user)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, @core_user, [:index, :destroy, :switch_to])
    end
  end #admin user

  context 'repository user' do
    setup do
      @user_in_core = users(:non_admin)
      @user_not_in_core = users(:dm)
      @core_user = users(:core_user)
    end

    should 'be able to switch to a core_user if they are a member of the core of the core_user' do
      allowed_abilities(@user_in_core, @core_user, [:switch_to])
    end

    should 'not be able to switch to a core_user if they are not a member of the core of the core_user' do
      denied_abilities(@user_not_in_core, @core_user, [:switch_to])
    end
  end #repository user

  context 'core user' do
    setup do
      @core_user = users(:core_user)
      @other_core_user = users(:core_user_two)
      @repo_user = users(:non_admin)
      @user = users(:non_repo_user)
    end

    should 'pass ability profile' do
      denied_abilities(@core_user, @core_user, [:index, :destroy])
      denied_abilities(@core_user, @other_core_user, [:index, :destroy])
      [@core_user, @repo_user, @user].each do |user|
        denied_abilities(@core_user, user, [:switch_to])
      end
    end
  end #core user
end
