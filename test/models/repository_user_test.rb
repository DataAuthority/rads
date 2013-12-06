require 'test_helper'

class RepositoryUserTest < ActiveSupport::TestCase
  should have_many :core_memberships
  should have_many(:cores).through(:core_memberships)
  should validate_presence_of :netid

  should 'be a User' do
    @user = users('dm')
    assert @user.is_a?(RepositoryUser), 'Admin should be an RepositoryUser object'
    assert @user.is_a?(User), 'Admin should be a User object'
  end

  context 'nil user' do
    setup do
      @other = users(:dm)
    end

    should 'pass ability profile' do
      allowed_abilities(nil, RepositoryUser.new, [:new, :create])
      denied_abilities(nil, @other, [:index, :show, :edit, :update, :destroy, :switch_to])
    end
  end #nil user

  context 'non_admin user' do
    setup do
      @self = users(:non_admin)
      @other = users(:dm)
    end

    should 'pass ability profile' do
      allowed_abilities(@self, @self, [:index, :show, :edit, :update, :destroy])
      denied_abilities(@self, @other, [:edit, :update, :destroy, :switch_to])
      allowed_abilities(@self, @other, [:index, :show])
      denied_abilities(@self, RepositoryUser.new, [:new, :create])
    end

  end #non_admin user

  context 'CoreUser' do
    setup do
      @self = users(:core_user)
    end

    should 'pass ability profile' do
      RepositoryUser.all.each do |other|
        allowed_abilities(@self, other, [:index, :show])
        denied_abilities(@self, other, [:edit, :update, :destroy, :switch_to])
      end
      denied_abilities(@self, RepositoryUser.new, [:new, :create])
    end
  end #core_user

  context 'ProjectUser' do
    setup do
      @self = users(:project_user)
    end

    should 'pass ability profile' do
      RepositoryUser.all.each do |other|
        allowed_abilities(@self, other, [:index, :show])
        denied_abilities(@self, other, [:edit, :update, :destroy, :switch_to])
      end
      denied_abilities(@self, RepositoryUser.new, [:new, :create])
    end
  end #ProjectUser

  context 'admin user' do
    setup do
      @self = users(:admin)
      @other = users(:dm)
    end

    should 'pass ability profile' do
      allowed_abilities(@self, @self, [:index, :show, :edit, :update])
      denied_abilities(@self, @self, [:destroy])
      allowed_abilities(@self, @other, [:index, :show, :edit, :update, :destroy, :switch_to])
      denied_abilities(@self, RepositoryUser.new, [:new, :create])
    end
  end #admin user

  context 'disabled users' do
    setup do
      @selves = [users(:admin), users(:non_admin)]
      @other = users(:dm)
    end
    should 'pass ability profile' do
      @selves.each do |user|
        user.is_enabled = false
        allowed_abilities(user, user, [:show])
        denied_abilities(user, user, [:index, :edit, :update, :destroy, :new, :create])
        denied_abilities(user, @other, [:index, :show, :edit, :update, :destroy, :new, :create, :switch_to])
      end
    end
  end
end
