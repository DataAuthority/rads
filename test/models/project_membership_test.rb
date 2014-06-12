require 'test_helper'

class ProjectMembershipTest < ActiveSupport::TestCase
  should belong_to :user
  should belong_to :project
  should validate_presence_of :user_id
  should validate_presence_of :project
  should validate_uniqueness_of(:project_id).scoped_to(:user_id)

  should allow_value(true).for(:is_administrator)
  should_respond_to(:is_administrator)
  should_respond_to(:is_administrator?)

  should allow_value(true).for(:is_data_consumer)
  should_respond_to(:is_data_consumer)
  should_respond_to(:is_data_consumer?)

  should allow_value(true).for(:is_data_producer)
  should_respond_to(:is_data_producer)
  should_respond_to(:is_data_producer?)

  should allow_value(true).for(:is_data_manager)
  should_respond_to(:is_data_manager)
  should_respond_to(:is_data_manager?)

  # Abilities

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, ProjectMembership, [:index] )
      denied_abilities(nil, project_memberships(:one), [:show, :destroy])
      denied_abilities(nil, ProjectMembership.new, [:new, :create])
    end
  end #nil user

  context 'user without membership project' do
    setup do
      @user = users(:admin)
      @project = projects(:one)
      @project_membership = project_memberships(:one)
    end

    should 'pass ability profile' do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, 'there should not be a ProjectMembership for this user'
      denied_abilities(@user, @project.project_memberships, [:index] )
      denied_abilities(@user, @project_membership, [:show, :edit, :update, :destroy])
      denied_abilities(@user, @project.project_memberships.build, [:new, :create])
    end
  end #non project member

  context 'user with membership in project' do
    setup do
      @user = users(:non_admin)
      @project = projects(:one)
      @self_membership = project_memberships(:one)
      @other_membership = project_memberships(:two)
    end

    should 'pass ability profile' do
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert !(pm.is_administrator? && pm.is_data_producer? && pm.is_data_consumer? && pm.is_data_manager?), 'user should not have any roles in the project'
      ProjectMembership.all.each do |pm|
        if pm.project.is_member? @user
          allowed_abilities(@user, pm, [:index, :show] )
        else
          denied_abilities(@user, pm, [:index, :show] )
        end
      end
      denied_abilities(@user, @other_membership, [:edit, :update, :destroy])
      denied_abilities(@user, @self_membership, [:edit, :update, :destroy])
      denied_abilities(@user, @project.project_memberships.build, [:new, :create])
    end
  end #project member

  context 'RepositoryUser with project_administrator role' do
    setup do
      @user = users(:p_m_administrator)
      @project = projects(:membership_test)
      @self_membership = project_memberships(:project_membership_administrator)
      @other_membership = project_memberships(:project_membership_consumer)
    end

    should 'pass ability profile' do
      assert @project.is_member?(@user), 'user should be a member of the project'
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert pm.is_administrator?, 'project_membership for user should be an administrator'
      allowed_abilities(@user, @other_membership, [:edit, :update, :destroy])
      denied_abilities(@user, @self_membership, [:edit, :update, :destroy])
      allowed_abilities(@user, @project.project_memberships.build(), [:new])
      allowed_abilities(@user, @project.project_memberships.build(user_id: users(:non_admin).id), [:create])
      denied_abilities(@user, @project.project_memberships.build(user_id: users(:project_user).id, is_administrator: true), [:create])
      denied_abilities(@user, @project.project_memberships.build(user_id: users(:core_user).id, is_administrator: true), [:create])
    end
  end #project administrator

  context 'ProjectUser' do
    setup do
      @user = users(:p_m_pu_producer)
    end

    should 'pass ability profile' do
      Project.all.each do |project|
        denied_abilities(@user, project.project_memberships, [:index] )
        denied_abilities(@user, project.project_memberships.build, [:new, :create])
      end
      denied_abilities(@user, @project_membership, [:show, :destroy])
    end
  end #ProjectUser

  context 'CoreUser' do
    setup do
      @user = users(:p_m_cu_producer)
    end

    should 'pass ability profile' do
      Project.all.each do |project|
        denied_abilities(@user, project.project_memberships, [:index] )
        denied_abilities(@user, project.project_memberships.build, [:new, :create])
      end
      denied_abilities(@user, @project_membership, [:show, :destroy])
    end
  end #CoreUser
end
