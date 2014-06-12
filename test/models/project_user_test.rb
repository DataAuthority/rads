require 'test_helper'

class ProjectUserTest < ActiveSupport::TestCase
   should belong_to :project
   should validate_presence_of :project

  # ability test
  context 'nil user' do
    setup do
      @project_user = users(:project_user)
    end

    should 'pass ability profile' do
      denied_abilities(nil, @project_user, [:index, :show, :update, :destroy, :switch_to])
    end
  end #nil user

  context 'admin user' do
    setup do
      @user = users(:admin)
      @project_user = users(:project_user)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, @project_user, [:index, :show, :update, :destroy, :switch_to])
    end
  end #admin user

  context 'repository user' do
    setup do
      @user_not_in_project = users(:non_admin)
      @user_member_in_project = users(:p_m_member)
      @user_dm_in_project = users(:p_m_dmanager)
      @user_dc_in_project = users(:p_m_consumer)
      @user_dp_in_project = users(:p_m_producer)
      @user_admin_in_project = users(:p_m_administrator)
      @project_user = users(:p_m_project_user)
    end

    should 'be able to switch to a project_user if they are a data_manager of the project of the project_user' do
      pm = @user_dm_in_project.project_memberships.where(project_id: @project_user.project_id, is_data_manager: true).first
      assert_not_nil pm
      assert pm.is_data_manager?, 'user should be a data_manager in the project for the project_user'
      allowed_abilities(@user_dm_in_project, @project_user, [:switch_to])
    end

    should 'not be able to switch to a project_user if they are not a data_manager of the project of the project_user' do
      [@user_not_in_project,
       @user_member_in_project,
       @user_dc_in_project,
       @user_dp_in_project,
       @user_admin_in_project].each do |tu|
         assert tu.project_memberships.where(project_id: @project_user.project_id, is_data_manager: true).empty?, "user #{ tu.name } should not be a data_manager in #{ @project_user.project.name }"
         denied_abilities(tu, @project_user, [:switch_to])
       end
    end

    should 'pass general ability profile' do
      denied_abilities(@user_in_project, @project_user, [:index, :show, :update, :destroy])
      denied_abilities(@user_not_in_project, @project_user, [:index, :show, :update, :destroy])
    end
  end #repository user

  context 'ProjectUser' do
    setup do
      @project_user = users(:project_user)
      @other_project_user = users(:project_user_two)
    end

    should 'pass ability profile' do
      denied_abilities(@project_user, @project_user, [:show, :update, :destroy])
      denied_abilities(@project_user, @other_project_user, [:show, :update, :destroy])
      User.all.each do |user|
        denied_abilities(@project_user, user, [:switch_to])
      end
    end
  end #ProjectUser

  context 'CoreUser' do
    setup do
      @core_user = users(:core_user)
      @other_core_user = users(:core_user_two)
    end

    should 'pass ability profile' do
      denied_abilities(@core_user, @core_user, [:show, :update, :destroy])
      denied_abilities(@core_user, @other_core_user, [:show, :update, :destroy])
      User.all.each do |user|
        denied_abilities(@core_user, user, [:switch_to])
      end
    end
  end #CoreUser
end
