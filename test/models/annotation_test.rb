require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase
  def self.general_abilities
    should 'pass general abilities' do
      assert_not_nil @user
      assert_not_nil @other_user
      assert_not_nil @users_record
      assert_not_nil @users_annotation
      assert_not_nil @other_users_record
      assert_not_nil @other_users_annotation
      assert_equal @user.id, @users_record.creator_id
      assert_equal @user.id, @users_annotation.creator_id
      assert @user.id != @other_users_record.creator_id, 'other_users_record should not be created by user'
      assert @user.id != @other_users_annotation.creator_id, 'other_users_annotation should not be created by user'

      allowed_abilities(@user, Annotation, [:index] )
      denied_abilities(@user, @other_users_record, [:show])
      allowed_abilities(@user, Annotation.new(creator_id: @user.id, record_id: @users_record.id, term: 'general_annotation'), [:new, :create])
      allowed_abilities(@user, @users_annotation, [:destroy])
      denied_abilities(@user, @other_users_annotation, [:destroy])
      denied_abilities(@user, @other_users_record, [:show])
      denied_abilities(@user, Annotation.new(creator_id: @other_user.id, record_id: @users_record.id, term: 'general_annotation'), [:new, :create])
      denied_abilities(@user, Annotation.new(creator_id: @user.id, record_id: @other_users_record.id, term: 'general_annotation'), [:new, :create])
    end
  end

  def self.project_member_abilities
    should 'pass project_member ability profile' do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert @project_affiliated_record.project.is_member?(@user), 'user should be a member of the project_affiliated_record project'
      allowed_abilities(@user, Annotation.new(creator_id: @user.id, record_id: @project_affiliated_record.record_id, term: 'annotation'), [:new, :create])
    end
  end

  def self.non_member_abilities
    should 'pass non project_member ability profile' do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert !@project_affiliated_record.project.is_member?(@user), 'user should not be a member of the project_affiliated_record project'
      denied_abilities(@user, Annotation.new(creator_id: @user.id, record_id: @project_affiliated_record.record_id, term: 'annotation'), [:new, :create])
    end
  end

  should belong_to :creator
  should belong_to :annotated_record
  should validate_presence_of :creator_id
  should validate_presence_of :record_id
  should validate_presence_of :term
  should_respond_to(:to_s)

  #should validate_uniqueness_of(:term).scoped_to(:creator_id, :record_id, :context).allow_nil does not work
  # in our case, as it wants to compare a string to a nil
  should "validate uniqueness of term scoped_to :creator_id, :record_id, and :context" do
    first = annotations(:membership_project_annotated_record)
    assert first.context.nil?, 'first context should be nil'
    assert first.valid?, 'first should be valid'

    new_a = Annotation.new(creator_id: first.creator_id, record_id: first.record_id, term: first.term)
    assert !new_a.valid?, 'new_a should not be valid'
    new_a.term = 'another_term'
    assert new_a.context.nil?, 'new_a context should be nil'
    assert new_a.valid?, 'new_a should be valid'
    new_a.term = first.term
    assert_equal first.term, new_a.term
    new_a.context = 'new_context'
    assert new_a.valid?, 'new_a should be valid with original term but new context'
  end

  context 'nil user' do

    should 'pass ability profile' do
      denied_abilities(nil, Annotation, [:index])
      denied_abilities(nil, Annotation.new, [:new, :create])
      denied_abilities(nil, annotations(:membership_project_annotated_record), [:destroy])
    end
  end #nil user

  context 'non_admin' do
    setup do
      @user = users(:non_admin)
      @other_user = users(:admin)
      @users_record = records(:user)
      @other_users_record = records(:admin)
      @users_annotation = annotations(:non_admin)
      @other_users_annotation = annotations(:membership_project_annotated_record)
    end

    general_abilities
  end #non_admin

  context 'CoreUser' do
    setup do
      @user = users(:core_user)
      @other_user = users(:admin)
      @users_record = records(:core_user)
      @other_users_record = records(:admin)
      @users_annotation = annotations(:core_user)
      @other_users_annotation = annotations(:membership_project_annotated_record)
    end

    general_abilities
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = users(:project_user)
      @other_user = users(:admin)
      @users_record = records(:project_user)
      @other_users_record = records(:admin)
      @users_annotation = annotations(:project_user)
      @other_users_annotation = annotations(:membership_project_annotated_record)
    end

    general_abilities
  end #ProjectUser

  context 'admin' do
    setup do
      @user = users(:admin)
      @other_user = users(:non_admin)
      @users_record = records(:admin)
      @other_users_record = records(:user)
      @users_annotation = annotations(:admin)
      @other_users_annotation = annotations(:membership_project_annotated_record)
    end

    general_abilities
  end #admin

  context 'CoreUser without membership in the project' do
    setup do
      @user = users(:core_user)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_abilities
  end #CoreUser without membership in the project

  context 'CoreUser with membership in the project but no roles' do
    setup do
      @user = users(:core_user)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
      
    project_member_abilities
  end #CoreUser with membership in the project but no roles

  context 'CoreUser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_cu_producer)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #CoreUser with the data_producer role in the project

  context 'CoreUser with the data_consumer role in the project' do
    setup do
      @user = users(:core_user)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #CoreUser with the data_consumer role in the project

  context 'Projectuser without membership in the project' do
    setup do
      @user = users(:project_user)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_abilities
  end #Projectuser without membership in the project

  context 'Projectuser with membership in the project but no roles' do
    setup do
      @user = users(:project_user)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Projectuser with membership in the project but no roles

  context 'Projectuser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_pu_producer)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Projectuser with the data_producer role in the project

  context 'ProjectUser with the data_consumer role in the project' do
    setup do
      @user = users(:project_user)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #ProjectUser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser without membership in the project' do
    setup do
      @user = users(:non_admin)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_abilities
  end #Non-Admin RepositoryUser without membership in the project

  context 'Non-Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:p_m_member)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Non-Admin RepositoryUser with membership in the project but no roles

  context 'Non-Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_producer)
      @project_affiliated_record = project_affiliated_records(:pm_cu_producer_affiliated)
    end

    project_member_abilities
  end #Non-Admin RepositoryUser with the data_producer role in the project

  context 'Non-Admin RepositoryUser with the data_consumer role in the project' do
    setup do
      @user = users(:p_m_consumer)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:p_m_administrator)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser with the data_manager role in the project' do
    setup do
      @user = users(:p_m_dmanager)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Admin Repositoryuser without membership in the project' do
    setup do
      @user = users(:admin)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_abilities
  end #Admin Repositoryuser without membership in the project

  context 'Admin Repositoryuser with membership in the project but no roles' do
    setup do
      @user = users(:admin)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Admin Repositoryuser with membership in the project but no roles

  context 'Admin Repositoryuser with the data_producer role in the project' do
    setup do
      @user = users(:admin)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id, is_data_producer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Admin Repositoryuser with the data_producer role in the project

  context 'Admin Repositoryuser with the data_consumer role in the project' do
    setup do
      @user = users(:admin)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Admin Repositoryuser with the data_consumer role in the project

  context 'Admin Repositoryuser with the administrator role in the project' do
    setup do
      @user = users(:admin)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id, is_administrator: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Admin Repositoryuser with the data_consumer role in the project

  context 'Admin Repositoryuser with the data_manager role in the project' do
    setup do
      @user = users(:admin)
      project = projects(:membership_test)
      project.project_memberships.create(user_id: @user.id, is_data_manager: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    project_member_abilities
  end #Admin Repositoryuser with the data_consumer role in the project

end
