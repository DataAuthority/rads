require 'test_helper'

class AnnotationsControllerTest < ActionController::TestCase
  def self.any_user_tests
    should 'be able to index annotations' do
      assert_not_nil @user
      get :index
      assert_response :success
    end

    should 'be able to index annotatons by creator_id' do
      assert_not_nil @user
      assert_not_nil @other_user_annotation
      get :index, creator_id: @other_user_annotation.creator_id
      assert_response :success
      assert_not_nil assigns(:annotations)
      assert assigns(:annotations).include?(@other_user_annotation), 'assigned annotations should include the existing annotation'
      assigns(:annotations).each do |a|
        assert_equal @other_user_annotation.creator_id, a.creator_id
      end
    end

    should 'be able to index annotatons by record_id' do
      assert_not_nil @user
      assert_not_nil @other_user_annotation
      get :index, record_id: @other_user_annotation.record_id
      assert_response :success
      assert_not_nil assigns(:annotations)
      assert assigns(:annotations).include?(@other_user_annotation), 'assigned annotations should include the existing annotation'
      assigns(:annotations).each do |a|
        assert_equal @other_user_annotation.record_id, a.record_id
      end
    end

    should 'be able to index annotatons by context' do
      assert_not_nil @user
      assert_not_nil @other_user_annotation
      assert_not_nil @other_user_annotation.context
      get :index, context: @other_user_annotation.context
      assert_response :success
      assert_not_nil assigns(:annotations)
      assert assigns(:annotations).include?(@other_user_annotation), 'assigned annotations should include the existing annotation'
      assigns(:annotations).each do |a|
        assert_equal @other_user_annotation.context, a.context
      end
    end

    should 'be able to index annotatons by term' do
      assert_not_nil @user
      assert_not_nil @other_user_annotation
      assert_not_nil @other_user_annotation.term
      get :index, term: @other_user_annotation.term
      assert_response :success
      assert_not_nil assigns(:annotations)
      assert assigns(:annotations).include?(@other_user_annotation), 'assigned annotations should include the existing annotation'
      assigns(:annotations).each do |a|
        assert_equal @other_user_annotation.term, a.term
      end
    end

    should 'be able to index annotatons by combination of creator_id, record_id, term, and context' do
      assert_not_nil @user
      assert_not_nil @other_user_annotation
      assert_not_nil @other_user_annotation.context
      assert_not_nil @other_user_annotation.term

      get :index, {
        creator_id: @other_user_annotation.creator_id,
        record_id: @other_user_annotation.record_id,
        context: @other_user_annotation.context,
        term: @other_user_annotation.term
      }

      assert_response :success
      assert_not_nil assigns(:annotations)
      assert assigns(:annotations).include?(@other_user_annotation), 'assigned annotations should include the existing annotation'
      assigns(:annotations).each do |a| 
        assert_equal @other_user_annotation.creator_id, a.creator_id
        assert_equal @other_user_annotation.record_id, a.record_id
        assert_equal @other_user_annotation.context, a.context
        assert_equal @other_user_annotation.term, a.term
      end
    end

    should 'get new with a record_id parameter for a record that they own' do
      assert_not_nil @user
      assert_not_nil @user_record
      assert_equal @user.id, @user_record.creator_id
      get :new, record_id: @user_record
      assert_response :success
    end

    should 'not get new with a record_id parameter for a record that they do not own' do
      assert_not_nil @user
      assert_not_nil @other_user_record
      assert @user.id != @other_user_record.creator_id, 'user should not own other_user_record'
      get :new, record_id: @other_user_record
      assert_redirected_to root_path
    end

    should 'be able to create an annotation on a record that they own' do
      assert_not_nil @user
      assert_not_nil @user_record
      assert_equal @user.id, @user_record.creator_id
      assert_difference('Annotation.count') do
        post :create, record_id: @user_record.id, annotation: {
          term: 'foo'
        }
      end
      assert_redirected_to annotations_url(record_id: @user_record.id)
    end

    should 'not be able to create an annotation on a record that they do own' do
      assert_not_nil @user
      assert_not_nil @other_user_record
      assert @user.id != @other_user_record.creator_id, 'user should not own other_user_record'
      assert_no_difference('Annotation.count') do
        post :create, record_id: @other_user_record.id, annotation: {
          term: 'foo'
        }
      end
      assert_redirected_to root_path
    end
 
    should 'be able to destroy their own annotation' do
      assert_not_nil @user
      assert_not_nil @user_annotation
      assert_equal @user.id , @user_annotation.creator_id
      assert_difference('Annotation.count', -1) do
        delete :destroy, id: @user_annotation
      end
      assert_redirected_to annotations_url
    end

    should 'not be able to destroy an annotation created by another user' do
      assert_not_nil @user
      assert_not_nil @other_user_annotation
      assert @user.id != @other_user_annotation.creator_id, 'user should not own other_user_annotation'
      assert_no_difference('Annotation.count') do
        delete :destroy, id: @other_user_annotation
      end
      assert_redirected_to root_path
    end
  end

  def self.not_project_member_tests
    should 'not get new with a record_id parameter for a record that they do not own, and do not have membership in the project to which it is affiliated' do
      assert_not_nil @user
      assert_not_nil @other_project_affiliated_record
      assert @user.id != @other_project_affiliated_record.affiliated_record.creator_id, 'user should not own other_project_affiliated_record record'
      assert !@other_project_affiliated_record.project.is_member?(@user), 'user should not be a member of the other_project_affiliated_record project'
      get :new, record_id: @other_project_affiliated_record.affiliated_record
      assert_redirected_to root_path
    end

    should 'not be able to create an annotation on a record that they do not own, and do not have membership in the project to which it is affiliated' do
      assert_not_nil @user
      assert_not_nil @other_project_affiliated_record
      assert @user.id != @other_project_affiliated_record.affiliated_record.creator_id, 'user should not own other_project_affiliated_record record'
      assert !@other_project_affiliated_record.project.is_member?(@user), 'user should not be a member of the other_project_affiliated_record project'
      assert_no_difference('Annotation.count') do
        post :create, record_id: @other_project_affiliated_record.affiliated_record, annotation: {
          term: 'foo'
        }
      end
      assert_redirected_to root_path
    end
  end

  def self.project_member_tests
    should 'get new with a record_id parameter for a record that they do not own, but have membership in the project to which it is affiliated' do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert @user.id != @project_affiliated_record.affiliated_record.creator_id, 'user should not own project_affiliated_record record'
      assert @project_affiliated_record.project.is_member?(@user), 'user should be a member of the project_affiliated_record project'
      get :new, record_id: @project_affiliated_record.affiliated_record
      assert_response :success
    end

    should 'be able to create an annotation on a record that they do not own, but have membership in the project to which it is affiliated' do
      assert_not_nil @user
      assert_not_nil @project_affiliated_record
      assert @user.id != @project_affiliated_record.affiliated_record.creator_id, 'user should not own project_affiliated_record record'
      assert @project_affiliated_record.project.is_member?(@user), 'user should be a member of the project_affiliated_record project'
      assert_difference('Annotation.count') do
        post :create, record_id: @project_affiliated_record.affiliated_record, annotation: {
          term: 'foo'
        }
      end
      assert_redirected_to annotations_url(record_id: @project_affiliated_record.affiliated_record.id)
      assert_not_nil assigns(:annotation)
      assert_equal 'foo', assigns(:annotation).term
    end
  end

  context 'Unauthenticated User' do
    setup do
      @record = records(:user)
      @annotation = annotations(:non_admin)
    end

    should 'not get index' do
      get :index
      assert_redirected_to sessions_new_url(:target => annotations_url)
    end

    should 'not get new' do
      get :new, record_id: @record
      assert_redirected_to sessions_new_url(:target => new_record_annotation_url(@record))
    end

    should 'not create an annotation' do
      assert_no_difference('Annotation.count') do
        post :create, record_id: @record.id, annotation: {
          term: 'foo'
        }
      end
      assert_response 302
    end

    should 'not destroy an annotation' do
      assert_no_difference('Annotation.count') do
        delete :destroy, id: @annotation
      end
      assert_response 302
    end
  end #Unauthenticated User


  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @user_record = records(:admin)
      @other_user_record = records(:user)
      @other_user_annotation = annotations(:core_user)
      @user_annotation = annotations(:admin)
    end
    any_user_tests
  end #Admin

  context 'NonAdmin' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @user_record = records(:user)
      @other_user_record = records(:admin)
      @other_user_annotation = annotations(:core_user)
      @user_annotation = annotations(:non_admin)
    end
    any_user_tests
  end #NonAdmin

  context 'CoreUser' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @user_record = records(:core_user)
      @other_user_record = records(:admin)
      @other_user_annotation = annotations(:project_user)
      @user_annotation = annotations(:core_user)
    end
    any_user_tests
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @user_record = records(:project_user)
      @other_user_record = records(:admin)
      @other_user_annotation = annotations(:core_user)
      @user_annotation = annotations(:project_user)
    end
    any_user_tests
  end #ProjectUser

  context 'CoreUser with no membership in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @other_project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    not_project_member_tests
  end #CoreUser with no membership in the project

  context 'CoreUser with membership in the project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id)
    end
    project_member_tests
  end #CoreUser with membership in the project but no roles

  context 'CoreUser with the data_consumer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
    end
    project_member_tests
  end #CoreUser with the data_consumer role in the project

  context 'CoreUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    project_member_tests
  end #CoreUser with the data_producer role in the project

  context 'ProjectUser with no membership in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @other_project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    not_project_member_tests
  end #ProjectUser with no membership in the project

  context 'ProjectUser with membership in the project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id)
    end
    project_member_tests
  end #ProjectUser with membership in the project but no roles

  context 'ProjectUser with the data_consumer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
    end
    project_member_tests
  end #ProjectUser with the data_consumer role in the project

  context 'ProjectUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    project_member_tests
  end #ProjectUser with the data_producer role in the project

  context 'Admin RepositoryUser with no membership in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @other_project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    not_project_member_tests
  end #Admin RepositoryUser with no membership in the project

  context 'Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id)
    end
    project_member_tests
  end #Admin RepositoryUser with membership in the project but no roles

  context 'Admin RepositoryUser with the data_consumer role in project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
    end
    project_member_tests
  end #Admin RepositoryUser with the data_consumer rolein the project

  context 'Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id, is_data_producer: true)
    end
    project_member_tests
  end #Admin RepositoryUser with the data_producer role in the project

  context 'Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id, is_administrator: true)
    end
    project_member_tests
  end #Admin RepositoryUser with the administrator role in the project

  context 'Admin RepositoryUser with the data_manager role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
      @project_affiliated_record.project.project_memberships.create(user_id: @user.id, is_data_manager: true)
    end
    project_member_tests
  end #Admin RepositoryUser with the data_manager role in the project

  context 'Non-Admin RepositoryUser with no membership in the project' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @other_project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    not_project_member_tests
  end #Non-Admin RepositoryUser with no membership in the project

  context 'Non-Admin RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:p_m_member)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    project_member_tests
  end #Non-Admin RepositoryUser with membership in the project but no roles

  context 'Non-Admin RepositoryUser with the data_consumer role in the project' do
    setup do
      @user = users(:p_m_consumer)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    project_member_tests
  end #Non-Admin RepositoryUser with the data_consumer role in the project

  context 'Non-Admin RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_producer)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_pu_producer_affiliated)
    end
    project_member_tests
  end #Non-Admin RepositoryUser with the data_producer role in the project

  context 'Non-Admin RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:p_m_administrator)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    project_member_tests
  end #Non-Admin RepositoryUser with the administrator role in the project

  context 'Non-Admin RepositoryUser with the data_manager role in the project' do
    setup do
      @user = users(:p_m_dmanager)
      authenticate_existing_user(@user, true)
      @project_affiliated_record = project_affiliated_records(:pm_producer_affiliated)
    end
    project_member_tests
  end #Non-Admin RepositoryUser with the data_manager role in the project
end
