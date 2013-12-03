require 'test_helper'

class ProjectMembershipTest < ActiveSupport::TestCase
  should belong_to :user
  should belong_to :project
  should validate_presence_of :user_id
  should validate_presence_of :project

  # Abilities

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, ProjectMembership, [:index] )
      denied_abilities(nil, project_memberships(:one), [:show, :destroy])
      denied_abilities(nil, ProjectMembership.new, [:new, :create])
    end
  end #nil user

  context 'non project member' do
    setup do
      @user = users(:admin)
      @project = projects(:one)
      @project_membership = project_memberships(:one)
    end

    should 'pass ability profile' do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, 'there should not be a ProjectMembership for this user'
      denied_abilities(@user, @project.project_memberships, [:index] )
      denied_abilities(@user, @project_membership, [:show, :destroy])
      denied_abilities(@user, @project.project_memberships.build, [:new, :create])
    end
  end #non project member

  context 'project member' do
    setup do
      @user = users(:non_admin)
      @project = projects(:one)
      @self_membership = project_memberships(:one)
      @other_membership = project_memberships(:two)
    end

    should 'pass ability profile' do
      assert @project.project_memberships.where(user_id: @user.id).exists?, 'there should be at least one ProjectMembership for this user in the project'
      ProjectMembership.all.each do |pm|
        if pm.project.is_member? @user
          allowed_abilities(@user, pm, [:index] )
        else
          denied_abilities(@user, pm, [:index] )
        end
      end
      allowed_abilities(@user, @other_membership, [:show, :destroy])
      allowed_abilities(@user, @self_membership, [:show])
      allowed_abilities(@user, @project.project_memberships.build, [:new, :create])
      denied_abilities(@user, @self_membership, [:destroy])
    end
  end #project member

end
