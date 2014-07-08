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
      get :index, record_filter: {affiliated_with_project: @project.id}
      assert_response 404
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
      assert @project_affiliated_record.project.project_memberships.where(user_id: @user.id).exists?, 'user should be a member in the project'
      assert_not_nil @project_affiliated_record.affiliated_record
      get :index, record_filter: {affiliated_with_project: @project.id}
      assert_response :success
      assert_not_nil assigns(:records)
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
end
