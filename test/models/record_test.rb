require 'test_helper'

class RecordTest < ActiveSupport::TestCase

  def self.should_pass_general_tests
    should 'pass ability profile' do
      assert_not_nil @user
      assert_not_nil @unowned_record
      assert_not_nil @other_user
      assert_not_nil @user_is_destroyed_record

      allowed_abilities(@user, Record, [:index] )
      allowed_abilities(@user, @user_record, [:index, :show, :download, :affiliate, :destroy])
      denied_abilities(@user, @unowned_record, [:index, :show, :download, :affiliate, :destroy])
      denied_abilities(@user, @user_is_destroyed_record, [:destroy])
      allowed_abilities(@user, @user.records.build, [:new, :create])
      denied_abilities(@user, @other_user.records.build, [:new, :create])
    end
  end

  def self.should_pass_nonmember_tests()
    should "pass nonmember tests" do
      assert_not_nil @user
      assert_not_nil @project
      assert_not_nil @project_record
      assert !@project.is_member?(@user), 'user should not be a member of the project'
      assert @project.is_affiliated_record?(@project_record), 'record should be affiliated with project'
      denied_abilities(@user, @project_record, [:index, :show, :download, :affiliate, :destroy])
    end
  end

  def self.should_pass_data_consumer_tests()
    should "pass data_consumer tests" do
      assert_not_nil @user
      assert_not_nil @project
      assert_not_nil @project_record
      assert @project.is_member?(@user), 'user should be a member of the project'
      assert @project.project_memberships.where(user_id: @user.id, is_data_consumer: true).exists?, 'user should have data_consumer in the project'
      assert @project.is_affiliated_record?(@project_record), 'record should be affiliated with project'
      allowed_abilities(@user, @project_record, [:index, :show, :download])
      denied_abilities(@user, @project_record, [:affiliate, :destroy])
    end
  end

  def self.should_pass_not_data_consumer_tests()
    should "pass not data_consumer tests" do
      assert_not_nil @user
      assert_not_nil @project
      assert_not_nil @project_record
      assert @project.is_member?(@user), 'user should be a member of the project'
      assert !@project.project_memberships.where(user_id: @user.id, is_data_consumer: true).exists?, 'user should not have data_consumer in the project'
      assert @project.is_affiliated_record?(@project_record), 'record should be affiliated with project'
      allowed_abilities(@user, @project_record, [:index, :show])
      denied_abilities(@user, @project_record, [:affiliate, :download, :destroy])
    end
  end

  should belong_to :creator
  should have_attached_file(:content)
  should have_many :project_affiliated_records
  should have_many(:projects).through(:project_affiliated_records)
  should have_many :audited_activities
  should accept_nested_attributes_for :project_affiliated_records

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp

    @user = users(:non_admin)
    @user_record = records(:user)
    @user_record.content = @test_content
    @user_record.save
    @expected_path = [ @user.storage_path,  @user_record.id, @user_record.content_file_name ].join('/')
    @user_is_destroyed_record = records(:user_is_destroyed)

    @admin = users(:admin)
    @admin_record = records(:admin)
    @admin_is_destroyed_record = records(:admin_is_destroyed)

    @core_user = users(:core_user)
    @core_user_record = records(:core_user)
    @core_user_is_destroyed_record = records(:core_user_is_destroyed)

    @project_user = users(:project_user)
    @project_user_record = records(:project_user)
    @project_user_is_destroyed_record = records(:project_user_is_destroyed)
  end

  teardown do
    @user_record.content.destroy
    @user_record.destroy
    @admin_record.content.destroy
    @admin_record.destroy
    @core_user_record.content.destroy
    @core_user_record.destroy
  end

  should 'not get a spoofing error with ruby files' do
    spoof_content_path = Rails.root.to_s + '/test/fixtures/attachments/spoof.rb'
    spoof_content = File.new(spoof_content_path)
    expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp
    user = users(:non_admin)
    user_record = records(:user_spoof)
    user_record.content = spoof_content
    assert user_record.valid?, "record valid? did not return true: #{user_record.errors.inspect}"
    assert user_record.save, 'record save did not return true'

    user_record.content.destroy
    user_record.destroy
  end

  should 'support destroy_content method' do
    assert_respond_to @user_record, 'destroy_content'
    assert_not_nil @user_record.content
    assert File.exists?(@user_record.content.path), 'content should exist'
    assert !@user_record.is_destroyed?, 'record.is_destroyed? should be false'
    assert @user_record.destroy_content, 'should be able to destroy record content'
    assert @user_record.is_destroyed?, 'record.is_destroyed? should be true'
    assert !@user_record.changed?, 'record should be saved'
    assert !File.exists?(@user_record.content.path), 'content should not exist'
  end

  should 'support find_by_md5 method' do
    assert_respond_to Record, 'find_by_md5'
    @trec = Record.find_by_md5(@expected_md5).take!
    assert_not_nil @trec
    assert_equal @user_record.id, @trec.id
  end
    
  should 'store content relative to user.storage_path' do
    assert_equal @expected_path, @user_record.content.path
    assert_equal @expected_md5, @user_record.content_fingerprint
  end

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, Record, [:index] )
      denied_abilities(nil, @user_record, [:show, :download, :destroy])
      denied_abilities(nil, @admin_record, [:show, :download, :destroy])
      denied_abilities(nil, Record.new, [:new, :create])
    end
  end #nil user
  
  context 'non_admin' do
    setup do
      @unowned_record = @admin_record
      @other_user = @admin
    end

    should_pass_general_tests

  end #non_admin

  context 'CoreUser' do
    setup do
      @user = @core_user
      @user_record = @core_user_record
      @unowned_record = @admin_record
      @other_user = @admin
      @user_is_destroyed_record = @core_user_is_destroyed_record
    end

    should_pass_general_tests

  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = @project_user
      @user_record = @project_user_record
      @unowned_record = @admin_record
      @other_user = @admin
      @user_is_destroyed_record = @project_user_is_destroyed_record
    end

    should_pass_general_tests

  end #ProjectUser

  context 'admin' do
    setup do
      @user = @admin
      @user_record = @admin_record
      @unowned_record = records(:user)
      @other_user = users(:non_admin)
      @user_is_destroyed_record = @admin_is_destroyed_record
    end

    should_pass_general_tests

  end #admin

  context 'CoreUser without membership in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:core_user)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_nonmember_tests

  end #CoreUser without membership in the project

  context 'CoreUser with membership in the project but no roles' do
    setup do
      @project = projects(:membership_test)
      @user = users(:core_user)
      @project.project_memberships.create(user_id: @user.id)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #CoreUser with membership in the project but no roles

  context 'CoreUser with the data_producer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:p_m_cu_producer)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #CoreUser with the data_producer role in the project

  context 'CoreUser with the data_consumer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:core_user)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_data_consumer_tests

  end #CoreUser with the data_consumer role in the project

  context 'Projectuser without membership in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:project_user)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_nonmember_tests

  end #Projectuser without membership in the project

  context 'Projectuser with membership in the project but no roles' do
    setup do
      @project = projects(:membership_test)
      @user = users(:project_user)
      @project.project_memberships.create(user_id: @user.id)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #Projectuser with membership in the project but no roles

  context 'Projectuser with the data_producer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:p_m_pu_producer)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #Projectuser with the data_producer role in the project

  context 'ProjectUser with the data_consumer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:project_user)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_data_consumer_tests

  end #Projectuser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser without membership in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:non_admin)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_nonmember_tests

  end #Non-Admin RepositoryUser without membership in the project

  context 'Non-Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @project = projects(:membership_test)
      @user = users(:p_m_member)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #Non-Admin RepositoryUser with membership in the project but no roles

  context 'Non-Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:p_m_producer)
      @project_record = records(:pm_pu_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #Non-Admin RepositoryUser with the data_producer role in the project

  context 'Non-Admin RepositoryUser with the data_consumer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:p_m_consumer)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_data_consumer_tests

  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Admin Repositoryuser without membership in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:admin)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_nonmember_tests

  end #Admin Repositoryuser without membership in the project

  context 'Admin Repositoryuser with membership in the project but no roles' do
    setup do
      @project = projects(:membership_test)
      @user = users(:admin)
      @project.project_memberships.create(user_id: @user.id)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #Admin Repositoryuser with membership in the project but no roles

  context 'Admin Repositoryuser with the data_producer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:admin)
      @project.project_memberships.create(user_id: @user.id, is_data_producer: true)
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_not_data_consumer_tests

  end #Admin Repositoryuser with the data_producer role in the project

  context 'Admin Repositoryuser with the data_consumer role in the project' do
    setup do
      @project = projects(:membership_test)
      @user = users(:admin)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true )
      @project_record = records(:pm_producer_affiliated_record)
    end

    should_pass_data_consumer_tests

  end #Admin Repositoryuser with the data_consumer role in the project

end
