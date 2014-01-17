require 'test_helper'

class RecordsControllerTest < ActionController::TestCase

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp

    @user = users(:non_admin)
    @user_record = records(:user)
    @user_record.content = @test_content
    @user_record.save
    @user_project = projects(:one)

    @admin = users(:admin)
    @admin_record = records(:admin)
    @admin_record.content = @test_content
    @admin_record.save
    @admin_project = projects(:two)
  end

  teardown do
    @user_record.content.destroy
    @user_record.destroy
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
      authenticate_existing_user(@admin, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
    end

    should 'get new' do
      get :new
      assert_response :success
    end

    should "post create" do
      assert_audited_activity(@admin, @admin, 'post', 'create', 'records') do
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
      assert_equal @admin.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @admin.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "post create, with project_affiliated_records_attributes" do
      assert_audited_activity(@admin, @admin, 'post', 'create', 'records') do
        assert_difference('Record.count') do
          assert_difference('ProjectAffiliatedRecord.count') do
            post :create, record: {
              content: fixture_file_upload('attachments/content.txt', 'text/plain'),
              project_affiliated_records_attributes: [{project_id: @admin_project.id}]
            }
            assert_not_nil assigns(:record)
          end
        end
      end
      assert_equal assigns(:record).id, assigns(:audited_activity).record_id
      assert_not_nil assigns(:record)
      assert_redirected_to record_path(assigns(:record))
      assert_equal @admin.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @admin.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assert @admin_project.is_affiliated_record?(assigns(:record)), 'record should be affiliated with admin_project'
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "show their record" do
      get :show, id: @admin_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @admin_record.id, assigns(:record).id
    end

    should "show someone elses record" do
      get :show, id: @user_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @user_record.id, assigns(:record).id
    end

    should 'download the content with download_content=true parameter to show' do
      get :show, id: @admin_record, download_content: true
      assert_response :success
      assert_equal "attachment; filename=\"#{ @admin_record.content_file_name }\"", @response.header["Content-Disposition"]
      assert_equal @admin_record.content_content_type, @response.header["Content-Type"]
    end

    should "destroy record by deleting the content, but keeping the record entry with is_disabled? true" do
      md5 = @admin_record.content_fingerprint
      name = @admin_record.content_file_name
      size = @admin_record.content_file_size
      path = @admin_record.content.path
      assert File.exist?( path ), 'content should be present before destroy'
      assert_audited_activity(@admin, @admin, 'delete', 'destroy', 'records') do
        assert_no_difference('Record.count') do
          delete :destroy, id: @admin_record
        end
      end
      assert_equal @admin_record.id, assigns(:audited_activity).record_id
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
      assert @user_record.content.present?, 'content should be present before destroy'
      assert_no_difference('AuditedActivity.count') do
        assert_no_difference('Record.count') do
          delete :destroy, id: @user_record
        end
      end
      assert_redirected_to root_path()
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert !@tr.is_destroyed?, 'content should not be destroyed'
      assert @tr.content.present?, 'content should be present after destroy'
    end

  end #Admin

  context 'NonAdmin' do

    setup do
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
    end

    should 'get new' do
      get :new
      assert_response :success
    end

    should "post create" do
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

    should "post create, with project_affiliated_records_attributes" do
      assert_audited_activity(@user, @user, 'post','create','records') do
        assert_difference('Record.count') do
          assert_difference('ProjectAffiliatedRecord.count') do
            post :create, record: {
              content: fixture_file_upload('attachments/content.txt', 'text/plain'),
              project_affiliated_records_attributes: [{project_id: @user_project.id.to_s}]
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
      assert @user_project.is_affiliated_record?(assigns(:record)), 'record should be affiliated with user_project'
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "show their record" do
      get :show, id: @user_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @user_record.id, assigns(:record).id
    end

    should "not show someone elses record" do
      get :show, id: @admin_record
      assert_redirected_to root_path()
    end

    should 'download the content with download_content=true parameter to show' do
      get :show, id: @user_record, download_content: true
      assert_response :success
      assert_equal "attachment; filename=\"#{ @user_record.content_file_name }\"", @response.header["Content-Disposition"]
      assert_equal @user_record.content_content_type, @response.header["Content-Type"]
    end

    should "destroy record by deleting the content, but keeping the record entry with is_disabled? true" do
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
      assert @admin_record.content.present?, 'content should be present before destroy'
      assert_no_difference('AuditedActivity.count') do
        assert_no_difference('Record.count') do
          delete :destroy, id: @admin_record
        end
      end
      assert_redirected_to root_path()
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert !@tr.is_destroyed?, 'content should not be destroyed'
      assert @tr.content.present?, 'content should be present after destroy'
    end

  end #NonAdmin

  context 'ProjectAffilatedRecord' do
    setup do
      @project_member = @user
      @non_member = users(:dm)
      @project = projects(:one)
      @project_affiliated_record = project_affiliated_records(:one).affiliated_record
    end

    should 'be indexable by project_member' do
      authenticate_existing_user(@project_member, true)
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).include? @project_affiliated_record
    end

    should 'not be indexable by non_member' do
      assert !@project.is_member?(@non_member), 'non_member should not be a member of the project'
      authenticate_existing_user(@non_member, true)
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
      assert !assigns(:records).include?(@project_affiliated_record)
    end

    should 'be showable by project_member' do
      authenticate_existing_user(@project_member, true)
      get :show, id: @project_affiliated_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @project_affiliated_record.id, assigns(:record).id
    end

    should 'not be showable by project_member' do
      authenticate_existing_user(@non_member, true)
      get :show, id: @project_affiliated_record
      assert_redirected_to root_path()
    end

    should 'be created automatically for any record created by a ProjectUser' do
      authenticate_existing_user(@project_member, true)
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
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
  end #ProjectAffiliatedRecord

  context 'index' do
    setup do
      @user_with_no_records = users(:dm)
      @member_project = projects(:one)
      @non_member_project = projects(:two)
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

    should 'accept record_filter[affiliated_with_project]=project_id parameter and show records affiliated with the project for project_member' do
      authenticate_existing_user(@user, true)
      assert @member_project.is_member?(@user), 'user should be a member of the member_project'
      record_count = @member_project.records.count
      assert record_count > 0, 'project should have affiliated records'
      get :index, record_filter: {affiliated_with_project: @member_project.id}
      assert_response :success
      assert_not_nil assigns(:records)
      assert_not_nil assigns(:project)
      assert_equal @member_project.id, assigns(:project).id
      assert_equal record_count, assigns(:records).count
      assigns(:records).each do |record|
        assert @member_project.is_affiliated_record?(record), 'record should be affiliated with member_project'
      end
    end

    should 'accept record_filter[affiliated_with_project]=project_id parameter but render user.records if user is not a member of the project' do
      authenticate_existing_user(@user, true)
      assert !@non_member_project.is_member?(@user), 'user should not be a member of the non_member_project'
      record_count = @user.records.count
      assert record_count > 0, 'user should have records'
      get :index, record_filter: {affiliated_with_project: @non_member_project.id}
      assert_response 404
      assert_nil assigns(:records)
    end
  end #index
end
