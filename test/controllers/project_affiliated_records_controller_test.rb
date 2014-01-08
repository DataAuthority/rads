require 'test_helper'

class ProjectAffiliatedRecordsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_affiliated_record = project_affiliated_records(:one)
    @unaffiliated_record = records(:user)
    @non_member = users(:admin)
    @project_affiliated_record = project_affiliated_records(:one)
  end

  context 'Not Authenticated' do
    should "not get :index" do
      get :index, project_id: @project
      assert_redirected_to sessions_new_url(:target => project_project_affiliated_records_url(@project))
    end

    should "not get :new" do
      get :new, project_id: @project
      assert_redirected_to sessions_new_url(:target => new_project_project_affiliated_record_url(@project))
    end

    should "not show project_affiliated_record" do
      get :show, project_id: @project, id: @project_affiliated_record
      assert_redirected_to sessions_new_url(:target => project_project_affiliated_record_url(@project, @project_affiliated_record))
    end

    should "not create project_affiliated_record" do
      create_params = { project_id: @project.id, project_affiliated_record: { record_id: records(:user) } }
      assert_no_difference('ProjectAffiliatedRecord.count') do
        post :create, create_params
      end
      assert_redirected_to sessions_new_url(:target => project_project_affiliated_records_url(create_params))
    end

    should "not destroy project_affiliated_record" do
      assert_no_difference('ProjectAffiliatedRecord.count') do
        delete :destroy, project_id: @project, id: @project_affiliated_record
      end
      assert_redirected_to sessions_new_url(:target => project_project_affiliated_record_url(@project, @project_affiliated_record))
    end
  end #Not Authenticated

  context 'ProjectMember' do
    setup do
      @user = users(:non_admin)
      @unaffiliated_record = records(:user)
      @create_params = {project_id: @project.id, project_affiliated_record: { record_id: @unaffiliated_record.id }}
      authenticate_existing_user(@user, true)
    end

    should "get :index" do
      get :index, project_id: @project
      assert_response :success
      assert_not_nil assigns(:project_affiliated_records)
      assert assigns(:project_affiliated_records).include? @project_affiliated_record
    end

    should "get :new" do
      get :new, project_id: @project
      assert_response :success
    end

    should "show project_affiliated_record" do
      get :show, project_id: @project, id: @project_affiliated_record
      assert_response :success
      assert_not_nil assigns(:project_affiliated_record)
      assert_equal @project_affiliated_record.id, assigns(:project_affiliated_record).id
    end

    should "create project_affiliated_record" do
      assert @project.is_member?(@user), 'project_member should be a member of the project'
      assert_equal @unaffiliated_record.creator_id, @user.id

      assert_difference('ProjectAffiliatedRecord.count') do
        post :create, @create_params
      end
      assert_not_nil assigns(:project_affiliated_record)
      assert_redirected_to project_url(@project)
    end

    should "destroy project_affiliated_record" do
      assert_difference('ProjectAffiliatedRecord.count', -1) do
        delete :destroy, project_id: @project, id: @project_affiliated_record
      end
      assert_redirected_to project_url(@project)
    end
  end #ProjectMember

  context 'Non ProjectMember' do
    setup do
      @user = users(:admin)
      @unaffiliated_record = records(:admin)
      @create_params = {project_id: @project.id, project_affiliated_record: { record_id: @unaffiliated_record.id }}
      authenticate_existing_user(@user, true)
    end

    should "not get :index" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, 'non_member should not be a member'
      get :index, project_id: @project
      assert_response :success
      assert assigns(:project_affiliated_records).empty?, 'project_affiliated_records list should be empty'
    end

    should "not get :new" do
      get :new, project_id: @project
      assert_redirected_to root_path()
    end

    should "not show project_affiliated_record" do
      get :show, project_id: @project, id: @project_affiliated_record
      assert_redirected_to root_path()
    end

    should "not create project_affiliated_record" do
      assert_no_difference('ProjectAffiliatedRecord.count') do
        post :create, @create_params
      end
      assert_redirected_to root_path()
    end

    should "not destroy project_affiliated_record" do
      assert_no_difference('ProjectAffiliatedRecord.count') do
        delete :destroy, project_id: @project, id: @project_affiliated_record
      end
      assert_redirected_to root_path()
    end
  end #Non ProjectMember
end
