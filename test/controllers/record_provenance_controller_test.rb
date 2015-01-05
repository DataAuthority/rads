require 'test_helper'

class RecordProvenanceControllerTest < ActionController::TestCase
  setup do
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    @test_content_path = Rails.root.join('test','fixtures','attachments','content.txt')
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp
    @record = records(:user)
    @record.content = @test_content
    @record.save
    @expected_filename = @record.content_file_name

    @unexpected_md5 = 'foobarbaz'
    @unexpected_filename = 'fl#@i3bbityjibbits.txt'
  end

  teardown do
    @record.content.destroy
    @record.destroy
  end

  should 'require a parameter to show' do
    get :show
    assert_response 404
  end

  context 'record_id' do
    should "get show without authentication" do
      get :show, record_id: @record.id
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "get show with authentication" do
      authenticate_user(users(:non_admin))
      get :show, record_id: @record.id
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "get show with switch_user" do
      authenticate_user(users(:non_admin))
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
      get :show, record_id: @record.id
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end
  end #record_id

  context 'md5' do
    should "get show without authentication" do
      get :show, md5: @expected_md5
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "get show with authentication" do
      authenticate_user(users(:non_admin))
      get :show, md5: @expected_md5
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "get show with switch_user" do
      authenticate_user(users(:non_admin))
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
      get :show, md5: @expected_md5
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end
  end #md5

  context 'unexpected md5' do
    should "not get show without authentication" do
      get :show, md5: @unexpected_md5
      assert_response 404
      assert (assigns(:records).count == 0), 'records should be empty'
    end

    should "not get show with authentication" do
      authenticate_user(users(:non_admin))
      get :show, md5: @unexpected_md5
      assert_response 404
      assert (assigns(:records).count == 0), 'records should be empty'
    end

    should "not get show with switch_user" do
      authenticate_user(users(:non_admin))
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
      get :show, md5: @unexpected_md5
      assert_response 404
      assert (assigns(:records).count == 0), 'records should be empty'
    end
  end #unexpected md5

  context 'filename' do
    should "get show without authentication" do
      get :show, filename: @expected_filename
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "get show with authentication" do
      authenticate_user(users(:non_admin))
      get :show, filename: @expected_filename
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "get show with switch_user" do
      authenticate_user(users(:non_admin))
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
      get :show, filename: @expected_filename
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end
  end #filename

  context 'filename md5 combinations' do
    should "return prov with valid md5-filename combination" do
      get :show, md5: @expected_md5, filename: @expected_filename
      assert_response :success
      assert_not_nil assigns(:records)
      assert (assigns(:records).count > 0), 'records should not be empty'
      assert_equal @record.id, assigns(:records).first.id
    end

    should "return 404 with valid md5, invalid filename combination" do
      get :show, md5: @expected_md5, filename: @unexpected_filename
      assert_response 404
      assert (assigns(:records).count == 0), 'records should be empty'
    end

    should "return 404 with invalid md5, valid filename combination" do
      get :show, md5: @unexpected_md5, filename: @expected_filename
      assert_response 404
      assert (assigns(:records).count == 0), 'records should be empty'
    end
  end #filename

end
