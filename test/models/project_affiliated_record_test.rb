require 'test_helper'

class ProjectAffiliatedRecordTest < ActiveSupport::TestCase
  should belong_to :project
  should belong_to :affiliated_record
  should validate_presence_of :project_id
  should validate_presence_of :affiliated_record

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, ProjectAffiliatedRecord, [:index] )
      denied_abilities(nil, ProjectAffiliatedRecord.new, [:new, :create])
      ProjectAffiliatedRecord.all.each do |par|
        denied_abilities(nil, par, [:show, :destroy])
      end
    end
  end #nil user

  context 'ProjectUser' do
    setup do
      @user = users(:project_user)
    end

    should 'pass ability profile' do
      denied_abilities(nil, ProjectAffiliatedRecord, [:index] )
      denied_abilities(nil, ProjectAffiliatedRecord.new, [:new, :create])
      ProjectAffiliatedRecord.all.each do |par|
        denied_abilities(nil, par, [:show, :destroy])
      end
    end    
  end #ProjectUser

  context 'ProjectMember' do
    setup do
      @user = users(:non_admin)
      @project = projects(:one)
      @project_affiliated_record = project_affiliated_records(:one)
      @unaffiliated_record = records(:user)
      @unowned_record = records(:admin)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, @project.project_affiliated_records.first, [:index])
      allowed_abilities(@user, @project.project_affiliated_records.build(), [:new])
      allowed_abilities(@user, @project.project_affiliated_records.build(record_id: @unaffiliated_record.id), [:create])
      denied_abilities(@user, @project.project_affiliated_records.build(record_id: @unowned_record.id), [:create])
      allowed_abilities(@user, @project_affiliated_record, [:show, :destroy])
    end
  end #ProjectMember

  context 'Non ProjectMember' do
    setup do
      @user = users(:admin)
      @project = projects(:one)
      @project_affiliated_record = project_affiliated_records(:one)
      @unaffiliated_record = records(:admin)
      @unowned_record = records(:user)
    end

    should 'pass abilities profile' do
      denied_abilities(@user, @project.project_affiliated_records.first, [:index])
      denied_abilities(@user, @project.project_affiliated_records.build(), [:new])
      denied_abilities(@user, @project.project_affiliated_records.build(record_id: @unaffiliated_record.id), [:create])
      denied_abilities(@user, @project.project_affiliated_records.build(record_id: @unowned_record.id), [:create])
      denied_abilities(@user, @project_affiliated_record, [:show, :destroy])      
    end
  end #Non ProjectMember
end
