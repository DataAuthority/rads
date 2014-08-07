require 'test_helper'

class RecordsControllerTest < ActionController::TestCase
  def self.any_user_tests
    should "get index" do
      assert_not_nil @user
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
    end

    should "not show someone elses record" do
      assert_not_nil @user
      assert_not_nil @other_user_record
      assert @user.id != @other_user_record.creator_id, 'user should not own other_user_record'
      get :show, id: @other_user_record
      assert_redirected_to root_path()
    end

    should 'get new' do
      assert_not_nil @user
      get :new
      assert_response :success
    end

    should "post create" do
      assert_not_nil @user
      assert_not_nil @expected_md5
      assert_audited_activity(@user, @user, 'post','create','records') do
        assert_difference('Record.count') do
          post :create, record: {
            content: fixture_file_upload('attachments/content.txt', 'text/plain')
          }
          assert_not_nil assigns(:record)
        end
      end
      assert_equal assigns(:record).id, assigns(:audited_activity).record_id
      assert_not_nil assigns(:record)
      assert_redirected_to record_path(assigns(:record))
      assert_equal @user.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @user.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assert File.exists? assigns(:record).content.path
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "post create with annotations_attributes to create annotations" do
      assert_not_nil @user
      assert_not_nil @expected_md5
      assert_audited_activity(@user, @user, 'post','create','records') do
        assert_difference('Record.count') do
          assert_difference('Annotation.count', 2) do
            post :create, record: {
              content: fixture_file_upload('attachments/content.txt', 'text/plain'),
              annotations_attributes: [
                {term: 'tag_term'},
                {term: 'context_term', context: 'context_context'}
              ]
            }
            assert_not_nil assigns(:record)
          end
        end
      end
      assert_equal assigns(:record).id, assigns(:audited_activity).record_id
      assert_not_nil assigns(:record)
      assert_redirected_to record_path(assigns(:record))
      assert_equal @user.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @user.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assert File.exists? assigns(:record).content.path
      tag_annotation = Annotation.where(record_id: assigns(:record).id, term: 'tag_term').first
      assert_not_nil tag_annotation
      assert_equal @user.id, tag_annotation.creator_id
      context_annotation = Annotation.where(record_id: assigns(:record).id, term: 'context_term', context: 'context_context').first
      assert_not_nil context_annotation
      assert_equal @user.id, context_annotation.creator_id
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "show their record" do
      assert_not_nil @user
      assert_not_nil @user_record
      assert_equal @user.id, @user_record.creator_id
      get :show, id: @user_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @user_record.id, assigns(:record).id
    end

    should "destroy their own record by deleting the content, but keeping the record entry with is_disabled? true" do
      assert_not_nil @user
      assert_not_nil @user_record
      assert_equal @user.id, @user_record.creator_id

      md5 = @user_record.content_fingerprint
      name = @user_record.content_file_name
      size = @user_record.content_file_size
      path = @user_record.content.path
      assert File.exist?( path ), 'content should be present before destroy'
      assert_audited_activity(@user, @user, 'delete', 'destroy', 'records') do
        assert_no_difference('Record.count') do
          delete :destroy, id: @user_record
        end
      end
      assert_equal @user_record.id, assigns(:audited_activity).record_id
      assert_redirected_to records_path
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert @tr.is_destroyed?, 'content should be destroyed'
      assert !File.exist?( path ), 'content should not be present after destroy'
      assert_equal md5, @tr.content_fingerprint
      assert_equal name, @tr.content_file_name
      assert_equal size, @tr.content_file_size
    end

    should "not destroy someone elses record" do
      assert_not_nil @user
      assert_not_nil @other_user_record
      assert @user.id != @other_user_record.creator_id, 'user should not own other_user_record'
      assert @other_user_record.content.present?, 'content should be present before destroy'
      assert_no_difference('AuditedActivity.count') do
        assert_no_difference('Record.count') do
          delete :destroy, id: @other_user_record
        end
      end
      assert_redirected_to root_path()
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert !@tr.is_destroyed?, 'content should not be destroyed'
      assert @tr.content.present?, 'content should be present after destroy'
    end

    should 'download content of their own record with download_content=true parameter to show' do
      assert_not_nil @user
      assert_not_nil @user_record
      assert_equal @user.id, @user_record.creator_id
      get :show, id: @user_record, download_content: true
      assert_response :success
      assert_equal "attachment; filename=\"#{ @user_record.content_file_name }\"", @response.header["Content-Disposition"]
      assert_equal @user_record.content_content_type, @response.header["Content-Type"]
    end
  end

  def self.non_member_tests
    should "not get affiliated records index" do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert !@project_affiliated_record.project.project_memberships.where(user_id: @user.id).exists?, 'user should not be a member in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :index, record_filter: {project_affiliation_filter_term_attributes: {project_id: @project.id} }
      assert_response :success
      assert assigns(:records).empty?, 'no records should have been returned'
    end

    should "not show affiliated record" do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert !@project_affiliated_record.project.project_memberships.where(user_id: @user.id).exists?, 'user should not be a member in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :show, id: @project_affiliated_record.affiliated_record
      assert_redirected_to root_url
    end
  end

  def self.any_member_tests
    should "get affiliated records index" do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert @project.is_affiliated_record?( @project_affiliated_record.affiliated_record), 'record should be afilliated with the project'
      assert @project_affiliated_record.project.project_memberships.where(user_id: @user.id).exists?, 'user should be a member in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :index, record_filter: {project_affiliation_filter_term_attributes: { project_id: @project.id} }
      assert_response :success
      assert_not_nil assigns(:records)
      assert !assigns(:records).empty?, 'there were records returned'
      assert assigns(:records).include?(@project_affiliated_record.affiliated_record), "records does not include affiliated_record"
    end

    should "show affiliated record" do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert @project_affiliated_record.project.project_memberships.where(user_id: @user.id).exists?, 'user should be a member in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :show, id: @project_affiliated_record.affiliated_record
      assert_response :success
    end
  end

  def self.data_consumer_tests
    should 'download the content of affiliated record via show' do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert @project_affiliated_record.project.project_memberships.where(user_id: @user.id, is_data_consumer: true).exists?, 'user should be a data_consumer in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :show, id: @project_affiliated_record.affiliated_record, download_content: true
      assert_response :success
   end
 end

  def self.not_data_consumer_tests
    should 'not download the content of affiliated record via show' do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert !@project_affiliated_record.project.project_memberships.where(user_id: @user.id, is_data_consumer: true).exists?, 'user should not be a data_consumer in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :show, id: @project_affiliated_record.affiliated_record, download_content: true
      assert_redirected_to root_url
   end
  end

  def self.data_producer_tests
    should "post create, with project_affiliated_records_attributes to project to which they are a data_producer" do
      assert_not_nil @user
      assert_not_nil @project
      assert @project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should be a data_producer in the project'
      assert_not_nil @expected_md5
      if @expected_project_affiliations.nil?
        @expected_project_affiliations = 1
      end
      assert_difference('Record.count') do
        assert_difference('ProjectAffiliatedRecord.count', +@expected_project_affiliations) do
          post :create, record: {
            content: fixture_file_upload('attachments/content.txt', 'text/plain'),
            project_affiliated_records_attributes: [{project_id: @project.id}]
          }
          assert_not_nil assigns(:record)
        end
      end
      assert_equal assigns(:record).id, assigns(:audited_activity).record_id
      assert_not_nil assigns(:record)
      assert_redirected_to record_path(assigns(:record))
      assert_equal @user.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @user.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assert File.exists? assigns(:record).content.path
      assert @project.is_affiliated_record?(assigns(:record)), 'record should be affiliated with project'
      assigns(:record).content.destroy
      assigns(:record).destroy
    end
  end

  def self.not_data_producer_tests
    should "not post create, with project_affiliated_records_attributes to project to which they are not a data_producer" do
      assert_not_nil @user
      assert_not_nil @project
      assert !@project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should not be a data_producer in the project'
      assert_no_difference('AuditedActivity.count') do
        assert_no_difference('Record.count') do
          assert_no_difference('ProjectAffiliatedRecord.count') do
            post :create, record: {
              content: fixture_file_upload('attachments/content.txt', 'text/plain'),
              project_affiliated_records_attributes: [{project_id: @project.id}]
            }
            assert_not_nil assigns(:record)
          end
        end
      end
      assert_redirected_to root_path
    end
  end

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp

    @non_admin_record = records(:user)
    @non_admin_record.content = @test_content
    @non_admin_record.save

    @admin = users(:admin)
    @admin_record = records(:admin)
    @admin_record.content = @test_content
    @admin_record.save
    @project = projects(:membership_test)
  end

  teardown do
    @non_admin_record.content.destroy
    @non_admin_record.destroy
    @admin_record.content.destroy
    @admin_record.destroy
  end

  context 'Unauthenticated User' do
    should 'not get index' do
      get :index
      assert_redirected_to sessions_new_url(:target => records_url)
    end
  end #Unauthenticated User

  context 'Admin' do
    setup do
      @user = users(:admin)
      @user_record = @admin_record
      @other_user_record = @non_admin_record
      authenticate_existing_user(@user, true)
    end

    any_user_tests
  end #Admin

  context 'NonAdmin' do

    setup do
      @user = users(:non_admin)
      @user_record = @non_admin_record
      @other_user_record = @admin_record
      authenticate_existing_user(@user, true)
    end

    any_user_tests
  end #NonAdmin

  context 'ProjectUser' do
    setup do
      @project_member = users(:p_m_member)
      authenticate_existing_user(@project_member, true)
      @puppet = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @puppet.id
    end

    should 'create a ProjectAffiliatedRecord with its Project for any record it creates' do
      assert_equal 'ProjectUser', @controller.current_user.type
      assert_audited_activity(@puppet, @project_member, 'post','create','records') do
        assert_difference('Record.count') do
          assert_difference('ProjectAffiliatedRecord.count') do
            post :create, record: {
              content: fixture_file_upload('attachments/content.txt', 'text/plain')
            }
            assert_not_nil assigns(:record)
          end
        end
      end
      assert_equal assigns(:record).id, assigns(:audited_activity).record_id
      assert ProjectAffiliatedRecord.where(record_id: assigns(:record).id, project_id: @puppet.project_id).exists?, 'ProjectAffiliatedRecord should have been created for project_user.project and newly created record'
    end

    should 'create a ProjectAffiliatedRecord with its Project even if affiliating the record with another project' do
      assert_equal 'ProjectUser', @controller.current_user.type
      assert_audited_activity(@puppet, @project_member, 'post','create','records') do
        assert_difference('Record.count') do
          assert_difference('ProjectAffiliatedRecord.count', 2) do
            post :create, record: {
              content: fixture_file_upload('attachments/content.txt', 'text/plain'),
              project_affiliated_records_attributes: [{project_id: @project.id}]
            }
            assert_not_nil assigns(:record)
          end
        end
      end
      assert_equal assigns(:record).id, assigns(:audited_activity).record_id
      assert ProjectAffiliatedRecord.where(record_id: assigns(:record).id, project_id: @puppet.project_id).exists?, 'ProjectAffiliatedRecord should have been created for project_user.project and newly created record'
      assert ProjectAffiliatedRecord.where(record_id: assigns(:record).id, project_id: @project.id).exists?, 'ProjectAffiliatedRecord should have been created for project and newly created record'
    end
  end #ProjectUser

  context 'index' do
    setup do
      @user = users(:non_admin)
      @user_with_no_records = users(:dm)
    end

    should 'render successfully when zero records have been returned' do
      authenticate_existing_user(@user_with_no_records, true)
      assert_equal 0, @user_with_no_records.records.count
      assert @user_with_no_records.records.empty?
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).empty?, 'records should be empty'  
    end

    should 'show current_user.records by default' do
      authenticate_existing_user(@user, true)
      record_count = @user.records.count
      assert record_count > 0, 'user should have records'
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
      assert_equal record_count, assigns(:records).count
      assigns(:records).each do |record|
        assert_equal @user.id, record.creator_id
      end
    end
  end #index

  #Project membership role testing
  context 'CoreUser with no membership in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #CoreUser with no membership in the project

  context 'CoreUser with membership in the project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #CoreUser with membership in the project but no roles

  context 'CoreUser with the data_consumer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    data_consumer_tests
    not_data_producer_tests
  end #CoreUser with the data_consumer role in the project

  context 'CoreUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    data_producer_tests
  end #CoreUser with the data_producer role in the project

  context 'ProjectUser with no membership in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #ProjectUser with no membership in the project

  context 'ProjectUser with membership in the project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #ProjectUser with membership in the project but no roles

  context 'ProjectUser with the data_consumer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
    end

    any_member_tests
    data_consumer_tests
    not_data_producer_tests
  end #ProjectUser with the data_consumer role in the project

  context 'ProjectUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @expected_project_affiliations = 2
    end

    any_member_tests
    not_data_consumer_tests
    data_producer_tests
  end #ProjectUser with the data_producer role in the project

  context 'Admin RepositoryUser with no membership in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #Admin RepositoryUser with no membership in the project

  context 'Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #Admin RepositoryUser with membership in the project but no roles

  context 'Admin RepositoryUser with the data_consumer role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    data_consumer_tests
    not_data_producer_tests
  end #Admin RepositoryUser with the data_consumer role in the project

  context 'Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_producer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    data_producer_tests
  end #Admin RepositoryUser with the data_producer role in the project

  context 'Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_administrator: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #Admin RepositoryUser with the administrator role in the project

  context 'Non-Admin RepositoryUser with no membership in the project' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    non_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #Non-Admin RepositoryUser with no membership in the project

  context 'Non-Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:p_m_member)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #Non-Admin RepositoryUser with membership in the project but no roles

  context 'Non-Admin RepositoryUser with the data_consumer role in the project' do
    setup do
      @user = users(:p_m_consumer)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    data_consumer_tests
    not_data_producer_tests
  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_producer)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_pu_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    data_producer_tests
  end #Non-Admin RepositoryUser with the data_producer role in the project

  context 'Non-Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:p_m_administrator)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end

    any_member_tests
    not_data_consumer_tests
    not_data_producer_tests
  end #Non-Admin RepositoryUser with the administrator role in the project
  #Project membership role testing

  context 'Query interface' do
    setup do
      @user_records = {
        pm_creator1: 'p_m_creator.txt',
        pm_creator2: 'nice_p_m_creator_file.txt',
        pm_creator3: 'created_by_p_m_creator.jpg'
      }
      @user_records.each do |record_name, target_file|
        this_record = records(record_name)
        this_path = Rails.root.to_s + "/test/fixtures/attachments/#{target_file}"
        this_record.content = File.new this_path
        this_record.save
        @user_records[record_name] = this_record
      end
      @user_records[:pm_creator1].created_at = @user_records[:pm_creator2].created_at - 10.days
      @user_records[:pm_creator3].created_at = @user_records[:pm_creator2].created_at + 10.days
      @user_records[:pm_creator1].save
      @user_records[:pm_creator3].destroy_content
      @other_user_record = records(:pm_producer_affiliated_record)
      @other_user_record.content = @test_content
      @other_user_record.save
      @project = projects(:membership_test)
      @user = users(:p_m_creator)
      authenticate_existing_user(@user, true)
    end

    teardown do
      @user_records.each do |name, to_destroy|
        unless to_destroy.is_destroyed?
          to_destroy.content.destroy
          to_destroy.destroy
        end
      end
    end

    should 'support query by record_created_by' do
      assert_no_difference('RecordFilter.count') do
        get :index, record_filter: {record_created_by: @other_user_record.creator_id}
      end
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      found = false
      assigns(:records).each do |rr|
        assert_equal @other_user_record.creator_id, rr.creator_id
        unless found
          found = (rr.id == @other_user_record.id)
        end
      end
      assert found, 'other_user_record should have been found'
    end

    should 'support query by :is_destroyed' do
      @other_user_record.is_destroyed = true
      @other_user_record.save
      found = {}

      assert @other_user_record.is_destroyed?, 'other_user_record should be destroyed'
      found[@other_user_record.id] = false

      assert @user_records[:pm_creator3].is_destroyed?, 'pm_creator3 should be destroyed'
      found[@user_records[:pm_creator3].id] = false

      assert_no_difference('RecordFilter.count') do
        get :index, record_filter: {is_destroyed: 'true'}, commit: 'Filter records'
      end
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.is_destroyed?, 'record should be destroyed'
        if found.has_key? rr.id
          unless found[rr.id]
            found[rr.id] = true
          end
        end
      end
      found.keys.each do |expected_id|
        assert found[expected_id], "expected record #{ expected_id } is missing"
      end
    end

    should 'support query by :record_created_on' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      get :index, record_filter: {record_created_on: @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d")}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"), rr.created_at.strftime("%Y-%m-%d")
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?(@user_records[:pm_creator1]), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?(@user_records[:pm_creator3]), 'returned records should not include pm_creator3'
    end

    should 'support query by :record_created_after' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      get :index, record_filter: {record_created_after: @user_records[:pm_creator1].created_at.strftime("%Y-%m-%d")}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0, 'there should be some records'
      assigns(:records).each do |rr|
        assert rr.created_at > @user_records[:pm_creator1].created_at
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?(@user_records[:pm_creator1]), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by :record_created_before' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      get :index, record_filter: {record_created_before: @user_records[:pm_creator3].created_at.strftime("%Y-%m-%d")}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.created_at < @user_records[:pm_creator3].created_at
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?(@user_records[:pm_creator3]), 'returned records should not include pm_creator3'
    end

    should 'allow record_created_before and record_created_after to be used together' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      [@other_user_record, @user_records[:pm_creator2]].each do |er|
        assert er.created_at > @user_records[:pm_creator1].created_at
        assert er.created_at < @user_records[:pm_creator3].created_at
      end
      get :index, record_filter: {
        record_created_after: @user_records[:pm_creator1].created_at.strftime("%Y-%m-%d"),
        record_created_before: @user_records[:pm_creator3].created_at.strftime("%Y-%m-%d")
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0, 'there should be some records returned'
      assigns(:records).each do |rr|
        assert rr.created_at > @user_records[:pm_creator1].created_at
        assert rr.created_at < @user_records[:pm_creator3].created_at
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'make record_created_on take precedence over record_created_before' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      get :index, record_filter: {
        record_created_on: @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"),
        record_created_before: @user_records[:pm_creator3].created_at.strftime("%Y-%m-%d")
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"), rr.created_at.strftime("%Y-%m-%d")
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'make record_created_on take precedence over record_created_after' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      get :index, record_filter: {
        record_created_on: @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"),
        record_created_after: @user_records[:pm_creator1].created_at.strftime("%Y-%m-%d")
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"), rr.created_at.strftime("%Y-%m-%d")
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'make record_created_on take precedence over record_created_before and record_created_after' do
      @other_user_record.update(created_at: @user_records[:pm_creator2].created_at)
      get :index, record_filter: {
        record_created_on: @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"),
        record_created_before: @user_records[:pm_creator3].created_at.strftime("%Y-%m-%d"),
        record_created_after: @user_records[:pm_creator1].created_at.strftime("%Y-%m-%d")
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal @user_records[:pm_creator2].created_at.strftime("%Y-%m-%d"), rr.created_at.strftime("%Y-%m-%d")
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :filename' do
      get :index, record_filter: {filename: @user_records[:pm_creator1].content_file_name}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal @user_records[:pm_creator1].content_file_name, rr.content_file_name
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
    end

    should 'support query by :filename with *suffix' do
      get :index, record_filter: {filename: '*.txt'}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/.txt$/)
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by :filename with prefix*' do
      get :index, record_filter: {filename: 'nice*'}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/nice.*/)
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :filename with prefix*suffix' do
      get :index, record_filter: {filename: '*p_m_creator*'}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/.*p\_m\_creator.*/)
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by :file_content_type' do
      [@other_user_record, @user_records[:pm_creator1]].each do |f|
        f.content_content_type = 'application/pdf'
        f.save
      end
      get :index, record_filter: {file_content_type: 'application/pdf'}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal 'application/pdf', rr.content_content_type
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :file_size' do
      get :index, record_filter: {file_size: @user_records[:pm_creator2].content_file_size}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size == @user_records[:pm_creator2].content_file_size
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :file_size_less_than' do
      get :index, record_filter: {file_size_less_than: @user_records[:pm_creator3].content_file_size}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size < @user_records[:pm_creator3].content_file_size
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :file_size_greater_than' do
      get :index, record_filter: {file_size_greater_than: @user_records[:pm_creator1].content_file_size}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size > @user_records[:pm_creator1].content_file_size
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'allow file_size_less_than and file_size_greater_than to be used together' do
      get :index, record_filter: {
        file_size_greater_than: @user_records[:pm_creator1].content_file_size,
        file_size_less_than: @user_records[:pm_creator3].content_file_size,
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size > @user_records[:pm_creator1].content_file_size, "#{rr.content_file_size} should be greater than #{ @user_records[:pm_creator1].content_file_size }"
        assert rr.content_file_size < @user_records[:pm_creator3].content_file_size, "#{rr.content_file_size} should be less than #{ @user_records[:pm_creator3].content_file_size }"
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'make file_size take precedence over file_size_less_than' do
      get :index, record_filter: {
        file_size: @user_records[:pm_creator3].content_file_size,
        file_size_less_than: @user_records[:pm_creator3].content_file_size
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size == @user_records[:pm_creator3].content_file_size
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'make file_size take precedence over file_size_greater_than' do
      get :index, record_filter: {
        file_size: @user_records[:pm_creator1].content_file_size,
        file_size_greater_than: @user_records[:pm_creator1].content_file_size,
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size == @user_records[:pm_creator1].content_file_size
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'make file_size take precedence over file_size_greather_than and file_size_less_than' do
      get :index, record_filter: {
        file_size: @user_records[:pm_creator3].content_file_size,
        file_size_greater_than: @user_records[:pm_creator1].content_file_size,
        file_size_less_than: @user_records[:pm_creator3].content_file_size,
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_size == @user_records[:pm_creator3].content_file_size
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by :file_md5hashsum' do
      assert_equal @user_records[:pm_creator1].content_fingerprint, @other_user_record.content_fingerprint
      get :index, record_filter: { file_md5hashsum: @user_records[:pm_creator1].content_fingerprint }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert_equal @user_records[:pm_creator1].content_fingerprint, rr.content_fingerprint
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :project_affiliation_filter_term' do
      assert @project.is_affiliated_record?(@other_user_record), 'other_user_record should be affiliated with membership_project'
      assert @project.is_affiliated_record?(@user_records[:pm_creator1]), 'pm_creator1 should be affiliated with membership_project'
      get :index, record_filter: {project_affiliation_filter_term_attributes: {project_id: @project.id}}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert @project.is_affiliated_record?( rr ), 'file should be affiliated with the project'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :annotation_filter_term' do
      get :index, record_filter: {annotation_filter_terms_attributes: [{created_by: @user.id, context: 'bar', term: 'foo'}]}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.annotations.where(creator_id: @user.id, context: 'bar', term: 'foo').exists?, 'record should have been annotated with the requested annotation'
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert !returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support query by :annotation_filter_term context: _ALL_ and return all contexts for given term' do
      get :index, record_filter: {annotation_filter_terms_attributes: [{context: '_ALL_', term: 'foo'}]}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.annotations.where(term: 'foo').exists?, 'record should have been annotated with the requested annotation'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by :annotation_filter_term with context and no term and return records with that context and any term' do
      get :index, record_filter: {annotation_filter_terms_attributes: [{context: 'bar'}]}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.annotations.where(context: 'bar').exists?, 'record should have been annotated with the requested annotation'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert returned_records.include?( @user_records[:pm_creator2] ), 'returned records should include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by :annotation_filter_term without a context and return only the given term and nil context' do
      get :index, record_filter: {annotation_filter_terms_attributes: [{term: 'foo'}]}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.annotations.where(context: nil, term: 'foo').exists?, 'record should have been annotated with the requested annotation'
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert !returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert returned_records.include?( @user_records[:pm_creator3] ), 'returned records should include pm_creator3'
    end

    should 'support query by multiple :annotation_filter_terms' do
      get :index, record_filter: {annotation_filter_terms_attributes: [
          {context: 'cell_line', term: 'NHEK'},
          {context: 'technology', term: 'DNaseHS'}
      ]}
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0, 'there should be some records'
      assigns(:records).each do |rr|
        assert rr.annotations.where(context: 'cell_line', term: 'NHEK').exists?, 'record should have been annotated with the requested first annotation'
        assert rr.annotations.where(context: 'technology', term: 'DNaseHS').exists?, 'record should have been annotated with the requested second annotation'
      end
      returned_records = assigns(:records).to_a
      assert !returned_records.include?( @user_records[:pm_creator1] ), 'returned records should not include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support combinations' do
      get :index, record_filter: {
        filename: 'p_m_creator*',
        annotation_filter_terms_attributes: [
          {context: 'bar', term: 'foo'},
        ],
        project_affiliation_filter_term_attributes: { project_id: @project.id }
      }
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/p\_m\_creator.*/)
        assert rr.annotations.where(context: 'bar', term: 'foo').exists?, 'record should have been annotated with the requested annotation'
        assert @project.is_affiliated_record?( rr ), 'file should be affiliated with the project'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert !returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'allow a named query to be saved and submitted' do
      test_name = 'a_test_saved_query'
      assert_difference('RecordFilter.count') do
        get :index, record_filter: {
          name: test_name,
          filename: 'p_m_creator*',
          annotation_filter_terms_attributes: [
            {context: 'bar', term: 'foo'},
          ],
          project_affiliation_filter_term_attributes: { project_id: @project.id }
        }, commit: 'Save Query and filter'
      end
      assert_response :success
      assert_not_nil assigns(:records)
      assert_not_nil assigns(:record_filter)
      assert_equal test_name, assigns(:record_filter).name
      assert assigns(:record_filter).persisted?, 'new record_filter should be persisted'
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/p\_m\_creator.*/)
        assert rr.annotations.where(context: 'bar', term: 'foo').exists?, 'record should have been annotated with the requested annotation'
        assert @project.is_affiliated_record?( rr ), 'file should be affiliated with the project'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert !returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'allow an un-named query to be sumitted with save, filter the results, but not save the query, instead render with errors' do
      assert_no_difference('RecordFilter.count') do
        get :index, record_filter: {
          filename: 'p_m_creator*',
          annotation_filter_terms_attributes: [
            {context: 'bar', term: 'foo'},
          ],
          project_affiliation_filter_term_attributes: { project_id: @project.id }
        }, commit: 'Save Query and filter'
      end
      assert_response :success
      assert_not_nil assigns(:records)
      assert_not_nil assigns(:record_filter)
      assert !assigns(:record_filter).persisted?, 'new record_filter should not be persisted'
      assert !assigns(:record_filter).valid?, 'new record_filter should not be valid'
      assert assigns(:records).count > 0
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/p\_m\_creator.*/)
        assert rr.annotations.where(context: 'bar', term: 'foo').exists?, 'record should have been annotated with the requested annotation'
        assert @project.is_affiliated_record?( rr ), 'file should be affiliated with the project'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert !returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'support record_filter_id for record_filter owned by user' do
      user_record_filter = RecordFilter.new(
                             name: "query_test_#{@user.id}",
                             user_id: @user.id, 
                             filename: '*.txt', 
                             project_affiliation_filter_term_attributes: {project_id: @project.id}, 
                             annotation_filter_terms_attributes: [{context: 'bar', term: 'foo'}]
                           )
      assert user_record_filter.valid?, "user_record_filter not valid #{ user_record_filter.errors.inspect }"
      assert user_record_filter.save
      get :index, record_filter_id: user_record_filter.id
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0, 'there should be some records'
      assigns(:records).each do |rr|
        assert rr.content_file_name.match(/.*\.txt/)
        assert rr.annotations.where(context: 'bar', term: 'foo').exists?, 'record should have been annotated with the requested annotation'
        assert @project.is_affiliated_record?( rr ), 'file should be affiliated with the project'
      end
      returned_records = assigns(:records).to_a
      assert returned_records.include?( @user_records[:pm_creator1] ), 'returned records should include pm_creator1'
      assert returned_records.include?( @other_user_record ), 'returned records should not include other_user_record'
      assert !returned_records.include?( @user_records[:pm_creator2] ), 'returned records should not include pm_creator2'
      assert !returned_records.include?( @user_records[:pm_creator3] ), 'returned records should not include pm_creator3'
    end

    should 'not allow record_filter_id query for record_filter not owned by user' do
      other_user_record_filter = record_filters(:project_user)
      assert other_user_record_filter.user_id != @user.id
      get :index, record_filter_id: other_user_record_filter
      assert_response 404
    end

  end #Query interface
end
