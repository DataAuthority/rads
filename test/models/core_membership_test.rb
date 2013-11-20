require 'test_helper'

class CoreMembershipTest < ActiveSupport::TestCase
  should belong_to :repository_user
  should belong_to :core
  should validate_presence_of :core
  should validate_presence_of :repository_user_id

  # Abilities

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, CoreMembership, [:index] )
      denied_abilities(nil, core_memberships(:one), [:show, :destroy])
      denied_abilities(nil, CoreMembership.new, [:new, :create])
    end
  end #nil user

  context 'non core member' do
    setup do
      @user = users(:admin)
      @core = cores(:one)
      @core_membership = core_memberships(:one)
    end

    should 'pass ability profile' do
      assert !@core.core_memberships.where(repository_user_id: @user.id).exists?, 'there should not be a CoreMembership for this user'
      denied_abilities(@user, @core.core_memberships, [:index] )
      denied_abilities(@user, @core_membership, [:show, :destroy])
      denied_abilities(@user, @core.core_memberships.build, [:new, :create])
    end
  end #non core member

  context 'core member' do
    setup do
      @user = users(:non_admin)
      @self_membership = core_memberships(:one)
      @other_membership = core_memberships(:two)
    end

    should 'pass ability profile' do
      assert CoreMembership.where(repository_user_id: @user.id).exists?, 'there should be at least one CoreMembership for this user'
      allowed_abilities(@user, CoreMembership, [:index] )
      allowed_abilities(@user, @other_membership, [:show, :destroy])
      allowed_abilities(@user, @self_membership, [:show])
      allowed_abilities(@user, cores(:one).core_memberships.build, [:new, :create])
      denied_abilities(@user, core_memberships(:one), [:destroy])
    end
  end #core member

end
