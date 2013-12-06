require 'test_helper'

class CoreTest < ActiveSupport::TestCase
  should belong_to :creator
  should validate_presence_of :name
  should validate_presence_of :creator_id
  should have_many :core_memberships
  should have_one :core_user

  setup do
    @core = cores(:one)
  end

  should 'support is_member? method to find out if a user is a member of the core' do
    assert_respond_to @core, 'is_member?'
    assert @core.core_memberships.count > 0, 'there should be core_memberships for the core'
    assert @core.is_member?(@core.core_memberships.first.repository_user), 'first core_membership repository_user should be a member of the core'
    assert !@core.is_member?(users(:admin)), 'admin should not be a member of the core'
  end

  # ability testing
  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, Core, [:index] )
      denied_abilities(nil, @core, [:show, :edit, :update])
      denied_abilities(nil, Core.new, [:new, :create])
    end
  end #nil user

  context 'CoreUser' do
    setup do
      @core_user = @core.core_user
      @other_core = cores(:two)
    end

    should 'pass ability profile' do
      allowed_abilities(@core_user, @core, [:index, :show])
      denied_abilities(@core_user, @other_core, [:index, :show])
      Core.all.each do |core|
        denied_abilities(@core_user, core, [:edit, :update])
      end
      denied_abilities(@core_user, Core.new, [:new, :create])
    end
  end #CoreUser

  context 'any RepositoryUser' do
    should 'pass ability profile' do
      RepositoryUser.all.each do |user|
        if user.is_enabled?
          allowed_abilities(user, Core, [:index] )
          allowed_abilities(user, @core, [:show] )
          allowed_abilities(user, Core.new, [:new, :create] )
          denied_abilities(user, @core, [:edit, :update])
        else
          denied_abilities(user, Core, [:index] )
          denied_abilities(user, @core, [:show, :edit, :update])
          denied_abilities(user, Core.new, [:new, :create])
        end
      end
    end
  end #RepositoryUser

  context 'ProjectUser' do
    should 'pass ability profile' do
      ProjectUser.all.each do |user|
        denied_abilities(user, Core, [:index] )
        denied_abilities(user, @core, [:show, :edit, :update])
        denied_abilities(user, Core.new, [:new, :create])
      end
    end
  end #ProjectUser
end
