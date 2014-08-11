require 'test_helper'

class ProjectAffiliatedRecordTest < ActiveSupport::TestCase
  def self.test_general_ability_profile
    should 'pass ability profile for user without membership in the project' do
      assert !@project.project_memberships.where(user_id: @user_without_membership.id).exists?, 'user should not have a membership'
      [
        project_affiliated_records(:pm_pu_producer_affiliated),
        project_affiliated_records(:pm_cu_producer_affiliated),
        project_affiliated_records(:pm_producer_affiliated),
      ].each do |par|
        denied_abilities(@user_without_membership, par, [:index, :show, :destroy])
      end
      denied_abilities(@user_without_membership, @project.project_affiliated_records.build(), [:new])
      u_r = @user_without_membership.records.first
      assert_not_nil u_r
      denied_abilities(@user_without_membership, @project.project_affiliated_records.build(record_id: u_r.id), [:create])
      denied_abilities(@user_without_membership, @project.project_affiliated_records.build(record_id: @unowned_record.id), [:create])
    end

    should 'pass ability profile for user without data producer role in the project' do
      pm = @project.project_memberships.where(user_id: @user_with_dp_in_project.id).first
      assert_not_nil pm
      assert pm.update(is_data_producer: false), 'should update status'
      assert !@project.project_memberships.where(user_id: @user_with_dp_in_project.id, is_data_producer: true).exists?, 'user should no longer be data producer'
      denied_abilities(@user_with_dp_in_project, @project.project_affiliated_records.build(), [:new])
      denied_abilities(@user_with_dp_in_project, @project.project_affiliated_records.build(record_id: @unaffiliated_record.id), [:create])
      denied_abilities(@user_with_dp_in_project, @project.project_affiliated_records.build(record_id: @unowned_record.id), [:create])
      [
        project_affiliated_records(:pm_pu_producer_affiliated),
        project_affiliated_records(:pm_cu_producer_affiliated),
        project_affiliated_records(:pm_producer_affiliated),
      ].each do |par|
        allowed_abilities(@user_with_dp_in_project, par, [:index, :show])
        denied_abilities(@user_with_dp_in_project, par, [:destroy])
      end
    end

    should 'pass ability profile for user with the data producer role in the project' do
      pm = @project.project_memberships.where(user_id: @user_with_dp_in_project.id).first
      assert_not_nil pm
      assert pm.is_data_producer?, 'user should be a data_producer'
      allowed_abilities(@user_with_dp_in_project, @project.project_affiliated_records.build(), [:new])
      allowed_abilities(@user_with_dp_in_project, @project.project_affiliated_records.build(record_id: @unaffiliated_record.id), [:create])
      [
        project_affiliated_records(:pm_pu_producer_affiliated),
        project_affiliated_records(:pm_cu_producer_affiliated),
        project_affiliated_records(:pm_producer_affiliated),
      ].each do |par|
        allowed_abilities(@user_with_dp_in_project, par, [:index, :show])
        if par.affiliated_record.creator_id == @user_with_dp_in_project.id
          allowed_abilities(@user_with_dp_in_project, par, [:destroy])
        else
          denied_abilities(@user_with_dp_in_project, par, [:destroy])
        end
      end
      denied_abilities(@user_without_membership, @project.project_affiliated_records.build(record_id: @unowned_record.id), [:create])
    end
  end

  should belong_to :project
  should belong_to :affiliated_record
  should validate_presence_of :project
  should validate_presence_of :affiliated_record
  should validate_uniqueness_of(:project_id).scoped_to(:record_id).with_message("record is already affiliated with this project")

  setup do
    @project = projects(:membership_test)
    @unowned_record = records(:admin)
  end

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
      @user_without_membership = users(:project_user)
      @user_with_dp_in_project = users(:p_m_pu_producer)
      @affiliated_record = project_affiliated_records(:pm_pu_producer_affiliated)
      @unaffiliated_record = records(:pm_pu_producer_unaffiliated_record)
    end
    test_general_ability_profile
  end #ProjectUser

  context 'CoreUser' do
    setup do
      @user_without_membership = users(:core_user)
      @user_with_dp_in_project = users(:p_m_cu_producer)
      @affiliated_record = project_affiliated_records(:pm_cu_producer_affiliated)
      @unaffiliated_record = records(:pm_cu_producer_unaffiliated_record)
    end
    test_general_ability_profile
  end #CoreUser

  context 'RepositoryUser' do
    setup do
      @user_without_membership = users(:non_admin)
      @user_with_dp_in_project = users(:p_m_producer)
      @affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:pm_producer_unaffiliated_record)
      @user_with_admin_in_project = users(:p_m_administrator)
    end

    test_general_ability_profile

    should 'pass ability profile for user with administrator role in the project' do
      pm = @project.project_memberships.where(user_id: @user_with_admin_in_project.id).first
      assert_not_nil pm
      assert pm.is_administrator?, 'user should be a project administrator'
      [
        project_affiliated_records(:pm_pu_producer_affiliated),
        project_affiliated_records(:pm_cu_producer_affiliated),
        project_affiliated_records(:pm_producer_affiliated),
      ].each do |par|
        allowed_abilities(@user_with_admin_in_project, par, [:index, :show, :destroy])
      end
      denied_abilities(@user_with_admin_in_project, @project.project_affiliated_records.build(), [:new])
      denied_abilities(@user_with_admin_in_project, @project.project_affiliated_records.build(record_id: records(:pm_administrator_record).id), [:create])
      denied_abilities(@user_without_membership, @project.project_affiliated_records.build(record_id: @unowned_record.id), [:create])
    end
  end #Repositoryuser
end
