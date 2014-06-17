require 'test_helper'

class ProjectAffiliatedRecordsControllerTest < ActionController::TestCase
  def self.non_member_tests
    should "not get :index" do
      assert_not_nil @project
      get :index, project_id: @project
      assert_redirected_to root_path
    end

    should "not show project_affiliated_record" do
      assert_not_nil @project
      assert_not_nil @project_affiliated_record
      get :show, project_id: @project, id: @project_affiliated_record
      assert_redirected_to root_path
    end
  end

  def self.any_member_tests
    should "get :index" do
      assert_not_nil @project
      get :index, project_id: @project
      assert_response :success
      assert_not_nil assigns(:project_affiliated_records)
      assert assigns(:project_affiliated_records).include? @project_affiliated_record
    end

    should "show project_affiliated_record" do
      assert_not_nil @project
      assert_not_nil @project_affiliated_record
      get :show, project_id: @project, id: @project_affiliated_record
      assert_response :success
      assert_not_nil assigns(:project_affiliated_record)
      assert_equal @project_affiliated_record.id, assigns(:project_affiliated_record).id
    end
  end

  def self.data_producer_tests
    should "create project_affiliated_record" do
      assert_not_nil @project
      assert_not_nil @unaffiliated_record
      assert @project.is_member?(@user), 'project_member should be a member of the project'
      assert @project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should be a data_producer in the project'
      assert_equal @unaffiliated_record.creator_id, @user.id

      assert_difference('ProjectAffiliatedRecord.count') do
        post :create, {project_id: @project.id, project_affiliated_record: { record_id: @unaffiliated_record.id }}
      end
      assert_not_nil assigns(:project_affiliated_record)
      assert_redirected_to project_url(@project)
    end

    should "not create project_affiliated_record for record that they do not own" do
      assert_not_nil @project
      assert_not_nil @unowned_record
      assert @project.is_member?(@user), 'project_member should be a member of the project'
      assert @project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should be a data_producer in the project'
      assert @unowned_record.creator_id != @user.id, 'user should not own unowned_record'

      assert_no_difference('ProjectAffiliatedRecord.count') do
        post :create, {project_id: @project.id, project_affiliated_record: { record_id: @unowned_record.id }}
      end
      assert_not_nil assigns(:project_affiliated_record)
      assert_redirected_to project_url(@project)
    end

    should "destroy project_affiliated_record that is owned by them" do
      assert_not_nil @project
      assert_not_nil @unaffiliated_record
      assert !@project.is_affiliated_record?(@unaffiliated_record), 'unaffiliated_record should not be affiliated with the project'
      assert_equal @user.id, @unaffiliated_record.creator_id
      existing_affiliated_record = ProjectAffiliatedRecord.create(project_id: @project.id, record_id: @unaffiliated_record.id)
      assert_not_nil existing_affiliated_record.id
      assert_difference('ProjectAffiliatedRecord.count', -1) do
        delete :destroy, project_id: @project, id: existing_affiliated_record.id
      end
      assert_redirected_to project_url(@project)
    end
  end

  def self.not_data_producer_tests
    should "not create project_affiliated_record" do
      assert_not_nil @project
      assert_not_nil @unaffiliated_record
      assert_equal @unaffiliated_record.creator_id, @user.id
      assert !@project.is_affiliated_record?(@unaffiliated_record), 'unaffiliated_record should not be affiliated with the project'

      assert_no_difference('ProjectAffiliatedRecord.count') do
        post :create, {project_id: @project.id, project_affiliated_record: { record_id: @unaffiliated_record.id }}
      end
      assert_redirected_to root_path
    end
  end

  def self.project_administrator_tests
    should "destroy any project_affiliated_record" do
      assert_not_nil @project
      assert_not_nil @project_affiliated_record
      assert @user.id != @project_affiliated_record.affiliated_record.creator_id, 'user should not own the project_affiliated record'
      assert_difference('ProjectAffiliatedRecord.count', -1) do
        delete :destroy, project_id: @project, id: @project_affiliated_record
      end
      assert_redirected_to project_url(@project)
    end
  end

  def self.not_project_administrator_tests
    should "not destroy project_affiliated_record that is not owned by them" do
      assert_not_nil @project
      assert_not_nil @project_affiliated_record
      assert @user.id != @project_affiliated_record.affiliated_record.creator_id, 'user should not own the project_affiliated_record'
      assert_no_difference('ProjectAffiliatedRecord.count') do
        delete :destroy, project_id: @project, id: @project_affiliated_record
      end
      assert_redirected_to project_url(@project)
    end
  end

  setup do
    @project = projects(:membership_test)
    @unowned_record = records(:admin)
  end

  context 'Not Authenticated' do
    setup do
      @project_affiliated_record = @project.project_affiliated_records.first
    end

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

  context 'CoreUser with no membership in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:core_user)
    end

    non_member_tests
    not_data_producer_tests
    not_project_administrator_tests
  end #CoreUser with no membership in the project

  context 'CoreUser with membership in the project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:core_user)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #CoreUser with membership in the project but no roles

  context 'CoreUser with the data_consumer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:core_user)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #CoreUser with the data_consumer role in the project

  context 'CoreUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:pm_cu_producer_unaffiliated_record)
    end

    any_member_tests
    data_producer_tests
    not_project_administrator_tests

  end #CoreUser with the data_producer role in the project

  context 'ProjectUser with no membership in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:project_user)
    end

    non_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #ProjectUser with no membership in the project

  context 'ProjectUser with membership in the project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:project_user)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #ProjectUser with membership in the project but no roles

  context 'ProjectUser with the data_consumer rolein the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @unaffiliated_record = records(:project_user)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #ProjectUser with the data_consumer role in the project

  context 'ProjectUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:pm_pu_producer_unaffiliated_record)
    end

    any_member_tests
    data_producer_tests
    not_project_administrator_tests

  end #ProjectUser with the data_producer role in the project

  context 'Admin RepositoryUser with no membership in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:admin)
    end

    non_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #Admin RepositoryUser with no membership in the project

  context 'Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:admin)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #Admin RepositoryUser with membership in the project but no roles

  context 'Admin RepositoryUser with the data_consumer rolein the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:admin)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #Admin RepositoryUser with the data_consumer role in the project

  context 'Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_producer: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:admin)
      @unowned_record = records(:user)
    end

    any_member_tests
    data_producer_tests
    not_project_administrator_tests

  end #Admin RepositoryUser with the data_producer role in the project

  context 'Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_administrator: true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:admin)
    end

    any_member_tests
    not_data_producer_tests
    project_administrator_tests

  end #Admin RepositoryUser with the administrator role in the project

  context 'Non-Admin RepositoryUser with no membership in the project' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:user)
    end

    non_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #Non-Admin RepositoryUser with no membership in the project

  context 'Non-Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:p_m_member)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:pm_member)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #Non-Admin RepositoryUser with membership in the project but no roles

  context 'Non-Admin RepositoryUser with the data_consumer rolein the project' do
    setup do
      @user = users(:p_m_consumer)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:pm_consumer_record)
    end

    any_member_tests
    not_data_producer_tests
    not_project_administrator_tests

  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_producer)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_pu_producer_affiliated)
      @unaffiliated_record = records(:pm_producer_unaffiliated_record)
    end

    any_member_tests
    data_producer_tests
    not_project_administrator_tests

  end #Non-Admin RepositoryUser with the data_producer role in the project

  context 'Non-Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:p_m_administrator)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @unaffiliated_record = records(:pm_administrator_record)
    end

    any_member_tests
    not_data_producer_tests
    project_administrator_tests

  end #Non-Admin RepositoryUser with the administrator role in the project
end
