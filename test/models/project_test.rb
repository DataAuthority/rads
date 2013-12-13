require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  should belong_to :creator
  should validate_presence_of :name
  should validate_presence_of :creator_id
  should have_many :project_memberships
  should have_one :project_user
  should have_many :project_affiliated_records
  should have_many(:records).through(:project_affiliated_records)

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
      denied_abilities(nil, @project, [:show, :edit, :update])
      denied_abilities(nil, Project.new, [:new, :create])
    end
  end #nil user

  context 'CoreUser' do
    should 'pass ability profile' do
      CoreUser.all.each do |core_user|
        if core_user.is_enabled?
          allowed_abilities(core_user, Project, [:index] )
          allowed_abilities(core_user, @project, [:show] )
          denied_abilities(core_user, @project, [:edit, :update])
          denied_abilities(core_user, Project.new, [:new, :create])
        else
          denied_abilities(core_user, Project, [:index] )
          denied_abilities(core_user, @project, [:show, :edit, :update])
          denied_abilities(core_user, Project.new, [:new, :create])
        end
      end
    end
  end #CoreUser

  context 'ProjectUser' do
    should 'pass ability profile' do
      ProjectUser.all.each do |project_user|
        if project_user.is_enabled?
          allowed_abilities(project_user, Project, [:index] )
          allowed_abilities(project_user, @project, [:show] )
          denied_abilities(project_user, @project, [:edit, :update])
          denied_abilities(project_user, Project.new, [:new, :create])
        else
          denied_abilities(project_user, Project, [:index] )
          denied_abilities(project_user, @project, [:show, :edit, :update])
          denied_abilities(project_user, Project.new, [:new, :create])
        end
      end
    end
  end #ProjectUser

  context 'RepositoryUser' do
    should 'pass ability profile' do
      RepositoryUser.all.each do |user|
        if user.is_enabled?
          allowed_abilities(user, Project, [:index] )
          allowed_abilities(user, @project, [:show] )
          allowed_abilities(user, Project.new, [:new, :create] )
          if @project.is_member?(user)
            allowed_abilities(user, @project, [:edit, :update])
          else
            denied_abilities(user, @project, [:edit, :update])
          end
        else
          denied_abilities(user, Project, [:index] )
          denied_abilities(user, @project, [:show, :edit, :update])
          denied_abilities(user, Project.new, [:new, :create])
        end
      end
    end
  end #any RepositoryUser
end
