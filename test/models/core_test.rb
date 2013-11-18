require 'test_helper'

class CoreTest < ActiveSupport::TestCase
  should belong_to :creator
  should validate_presence_of :name
  should validate_presence_of :creator_id

  setup do
    @core = cores(:one)
  end

  # ability testing
  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, Core, [:index] )
      denied_abilities(nil, @core, [:show, :edit, :update])
      denied_abilities(nil, Record.new, [:new, :create])
    end
  end #nil user

  context 'Non RepositoryUser' do
    setup do
      @user = users(:non_repo_user)
    end
    should 'pass ability profile' do
      allowed_abilities(@user, Core, [:index] )
      allowed_abilities(@user, @core, [:show] )
      denied_abilities(@user, @core, [:edit, :update])
      denied_abilities(@user, Core.new, [:new, :create])
    end
  end

  context 'any RepositoryUser' do
    should 'pass ability profile' do
      RepositoryUser.where(is_enabled: true).each do |user|
        allowed_abilities(user, Core, [:index] )
        allowed_abilities(user, @core, [:show] )
        allowed_abilities(user, Core.new, [:new, :create] )
        denied_abilities(user, @core, [:edit, :update])
      end
    end
  end #admin user

end
