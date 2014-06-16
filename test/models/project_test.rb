require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  should belong_to :creator
  should validate_presence_of :name
  should validate_presence_of :creator_id
  should have_many :project_memberships
  should have_one :project_user
  should have_many :project_affiliated_records
  should have_many(:records).through(:project_affiliated_records)
  should accept_nested_attributes_for :project_affiliated_records
  should accept_nested_attributes_for :project_memberships

  setup do
    @project = projects(:one)
  end

  should 'support is_member? method to find out if a user is a member of the project' do
    assert_respond_to @project, 'is_member?'
    assert @project.project_memberships.count > 0, 'there should be project_memberships for the project'
    assert @project.is_member?(@project.project_memberships.first.user), 'first project_membership user should be a member of the project'
    assert !@project.is_member?(users(:admin)), 'admin should not be a member of the project'
  end

  should 'support is_affiliated_record? method to find out if a record is a affiliated with the project' do
    assert_respond_to @project, 'is_affiliated_record?'
    assert @project.project_affiliated_records.count > 0, 'there should be project_affiliated_records for the project'
    affiliated_record = @project.project_affiliated_records.first.affiliated_record
    assert @project.project_affiliated_records.where(record_id: affiliated_record.id).exists?, 'the record should exist'
    assert @project.is_affiliated_record?(affiliated_record), 'first project_affiliation should be affiliated with the project'
    assert !@project.is_affiliated_record?(records(:admin)), 'admin should not be a member of the project'
  end

  # ability testing
  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, Project, [:index] )
      denied_abilities(nil, @project, [:show, :edit, :update, :update_attributes])
      denied_abilities(nil, Project.new, [:new, :create])
    end
  end #nil user

  context 'CoreUser' do

    should 'pass ability profile' do
      cannot_update_tested = producer_tested = false
      CoreUser.all.each do |core_user|
        if core_user.is_enabled?
          allowed_abilities(core_user, Project, [:index] )
          denied_abilities(core_user, Project.new, [:new, :create])
          Project.all.each do |project|
            allowed_abilities(core_user, project, [:show] )
            denied_abilities(core_user, project, [:edit])
            if core_user.project_memberships.where(project_id: project.id, is_data_producer: true).exists?
              producer_tested = true
              allowed_abilities(core_user, project, [:update])
              denied_abilities(core_user, project, [:update_attributes])
            else
              cannot_update_tested = true
              denied_abilities(core_user, project, [:update, :update_attributes])
            end
          end
        else
          denied_abilities(core_user, Project, [:index] )
          denied_abilities(core_user, @project, [:show, :edit, :update, :update_attributes])
          denied_abilities(core_user, Project.new, [:new, :create])
        end
      end
      assert cannot_update_tested, 'user that cannot_update should have been tested'
      assert producer_tested, 'data_prodcuer in project should have been tested'
    end
  end #CoreUser

  context 'ProjectUser' do
    should 'pass ability profile' do
      cannot_update_tested = producer_tested = false
      ProjectUser.all.each do |project_user|
        if project_user.is_enabled?
          allowed_abilities(project_user, Project, [:index] )
          denied_abilities(project_user, Project.new, [:new, :create])
          Project.all.each do |project|
            allowed_abilities(project_user, project, [:show] )
            denied_abilities(project_user, project, [:edit])
            if project_user.project_memberships.where(project_id: project.id, is_data_producer: true).exists?
              producer_tested = true
              allowed_abilities(project_user, project, [:update])
              denied_abilities(project_user, project, [:update_attributes])
            else
              cannot_update_tested = true
              denied_abilities(project_user, project, [:update, :update_attributes])
            end
          end
        else
          denied_abilities(project_user, Project, [:index] )
          denied_abilities(project_user, @project, [:show, :edit, :update, :update_attributes])
          denied_abilities(project_user, Project.new, [:new, :create])
        end
      end
      assert cannot_update_tested, 'user that cannot_update should have been tested'
      assert producer_tested, 'data_prodcuer in project should have been tested'
    end
  end #ProjectUser

  context 'RepositoryUser' do
    should 'pass ability profile' do
      cannot_update_tested = member_without_producer_or_administrator_tested = producer_tested = producer_not_administrator_tested = administrator_tested = false
      RepositoryUser.all.each do |user|
        if user.is_enabled?
          allowed_abilities(user, Project, [:index] )
          allowed_abilities(user, Project.new, [:new, :create] )
          Project.all.each do |project|
            allowed_abilities(user, project, [:show] )
            pm = user.project_memberships.where(project_id: project.id).first
            if pm.nil?
              cannot_update_tested = true
              denied_abilities(user, project, [:edit, :update, :update_attributes])
            else
             if (pm.is_administrator? || pm.is_data_producer?)
               if pm.is_data_producer?
                 producer_tested = true
                 allowed_abilities(user, project, [:update])
                 unless pm.is_administrator?
                   producer_not_administrator_tested = true
                   denied_abilities(user, project, [:edit, :update_attributes])
                 end
               end
               if pm.is_administrator?
                 administrator_tested = true
                 allowed_abilities(user, project, [:edit, :update, :update_attributes])
               end
             else
                member_without_producer_or_administrator_tested = true
                denied_abilities(user, project, [:edit, :update, :update_attributes])
             end
            end
         end
        else
          denied_abilities(user, Project, [:index] )
          denied_abilities(user, @project, [:show, :edit, :update, :update_attributes])
          denied_abilities(user, Project.new, [:new, :create])
        end
      end
      assert cannot_update_tested, 'user that cannot_update should have been tested'
      assert member_without_producer_or_administrator_tested, 'member without producer or administrator role should have been tested'
      assert producer_tested, 'data_prodcuer in project should have been tested'
      assert producer_not_administrator_tested, 'data_prodcuer that is not an administrator in project should have been tested'
      assert administrator_tested, 'project administrator should have been tested'
    end
  end #any RepositoryUser
end
