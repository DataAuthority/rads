require 'test_helper'

class RecordFiltersControllerTest < ActionController::TestCase
  def self.owned_by_user()
    should 'be able to index their record_filters' do
      assert_not_nil @user
      assert_not_nil @user_record_filters
      assert @user_record_filters.size > 0
      @user_record_filters.each do |urf|
        assert_equal @user.id, urf.user_id
      end

      get :index
      assert_response :success
      assert_not_nil assigns(:record_filters)
      assert_equal @user_record_filters.count, assigns(:record_filters).count
      assigns(:record_filters).each do |rf|
        assert_equal @user.id, rf.user_id
      end
    end

    should 'be able to show a record_filter that belongs to them' do
      assert_not_nil @user
      assert_not_nil @user_record_filters
      assert @user_record_filters.size > 0
      @user_record_filters.each do |urf|
        assert_equal @user.id, urf.user_id
      end
      user_record_filter = @user_record_filters[0]
      get :show, id: user_record_filter
      assert_response :success
      assert_not_nil assigns(:record_filter)
      assert_equal user_record_filter.id, assigns(:record_filter).id
    end

    should 'be able to edit a record_filter that belongs to them' do
      assert_not_nil @user
      assert_not_nil @user_record_filters
      assert @user_record_filters.size > 0
      @user_record_filters.each do |urf|
        assert_equal @user.id, urf.user_id
      end
      user_record_filter = @user_record_filters[0]
      get :edit, id: user_record_filter
      assert_response :success
      assert_not_nil assigns(:record_filter)
      assert_equal user_record_filter.id, assigns(:record_filter).id
    end

    should 'be able to update a record_filter that belongs to them' do
      assert_not_nil @user
      assert_not_nil @user_record_filters
      assert @user_record_filters.size > 0
      @user_record_filters.each do |urf|
        assert_equal @user.id, urf.user_id
      end
      user_record_filter = @user_record_filters[0]
      change = {
        record_created_by: 33,
        is_destroyed: !user_record_filter.is_destroyed,
        created_on: Date.today - 10,
        filename: "random_test_filename.tpg"
      }
      patch :update, id: user_record_filter, record_filter: change
      assert_not_nil assigns(:record_filter)
      assert_equal user_record_filter.id, assigns(:record_filter).id
      trf = RecordFilter.find(user_record_filter.id)
      change.each do |changed, changed_to|
        assert_equal changed_to, trf.send(changed)
      end
    end

    should 'be able to get new' do
      assert_not_nil @user
      get :new
      assert_response :success
    end

    should 'be able to create a record_filter' do
      assert_not_nil @user
      new_record_filter = {
        name: "TEST_#{@user.to_s}_FILTER",
        created_before: (Date.today - 10).strftime("%Y-%m-%d"),
        created_after: (Date.today + 10).strftime("%Y-%m-%d"),
        is_destroyed: true,
        file_size_less_than: 100,
        file_size_greater_than: 10,
        filename: "random_test_filename.tpg"
      }
      assert_difference('RecordFilter.count') do
        post :create, record_filter: new_record_filter
        assert assigns(:record_filter).errors.empty?, "#{ assigns(:record_filter).errors.inspect }"
      end
      assert_redirected_to record_filters_path
      assert_not_nil assigns(:record_filter)
      new_record_filter.each do |attribute, created_with|
        if assigns(:record_filter).send(attribute).is_a? Date
          created_with = Date.parse(created_with)
        end
        assert_equal created_with, assigns(:record_filter).send(attribute)
      end
    end

    should 'be able to destroy a record_filter that belongs to them' do
      assert_not_nil @user
      assert_not_nil @user_record_filters
      assert @user_record_filters.size > 0
      @user_record_filters.each do |urf|
        assert_equal @user.id, urf.user_id
      end
      user_record_filter = @user_record_filters[0]
      assert_difference('RecordFilter.count', -1) do
        delete :destroy, id: user_record_filter.id
      end
      assert_not_nil assigns(:record_filter)
      assert !@user.record_filters.where(id: user_record_filter.id).exists?, 'record_filter should no longer exist'
    end
  end

  def self.not_owned_by_user()
    should 'not be able to show a record that they do not own' do
      assert_not_nil @user
      assert_not_nil @other_user_record_filter
      get :show, id: @other_user_record_filter
      assert_redirected_to root_path
    end

    should 'not be able to edit a record that they do not own' do
      assert_not_nil @user
      assert_not_nil @other_user_record_filter
      get :edit, id: @other_user_record_filter
      assert_redirected_to root_path
    end

    should 'not be able to update a record that they do not own' do
      assert_not_nil @user
      assert_not_nil @other_user_record_filter
      change = {
        filename: "random_test_filename.tpg"
      }
      assert @other_user_record_filter.filename != change[:filename], "other_user_record_filter filename should be different from change"
      patch :update, id: @other_user_record_filter, record_filter: change
      assert_redirected_to root_path
      trf = RecordFilter.find(@other_user_record_filter.id)
      change.keys.each do |attempted|
        assert_equal @other_user_record_filter.filename, trf.send(attempted)
      end
    end

    should 'not be able to destroy a record that they do not own' do
      assert_not_nil @user
      assert_not_nil @other_user_record_filter
      assert_no_difference('RecordFilter.count') do
        delete :destroy, id: @other_user_record_filter
      end
      assert_redirected_to root_path
    end
  end

  def self.update_functionality()
    should 'be able to update a record_filter to remove a parameter' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      assert_not_nil @user_record_filter.created_on
      change = {
        created_on: nil
      }
      patch :update, id: @user_record_filter, record_filter: change
      assert_not_nil assigns(:record_filter)
      assert_equal @user_record_filter.id, assigns(:record_filter).id
      trf = RecordFilter.find(@user_record_filter.id)
      assert trf.created_on.nil?, 'created_on should now be nil after update'
    end

    should 'be able to update a record_filter to add a project_affiliation_filter_term' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      assert @user_record_filter.project_affiliation_filter_term.destroy, 'project_affiliation_filter_term destroyed'
      change = {
        project_affiliation_filter_term_attributes: {project_id: 444}
      }
      assert_difference('ProjectAffiliationFilterTerm.count') do
        patch :update, id: @user_record_filter, record_filter: change
      end
      assert_not_nil assigns(:record_filter)
      assert_equal @user_record_filter.id, assigns(:record_filter).id
      trf = RecordFilter.find(@user_record_filter.id)
      assert_not_nil trf.project_affiliation_filter_term
      assert_equal change[:project_affiliation_filter_term_attributes][:project_id], trf.project_affiliation_filter_term.project_id
    end

    should 'be able to update a record_filter to remove a project_affiliation_filter_terms_attribute' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      assert_not_nil @user_record_filter.project_affiliation_filter_term
      change = {
        project_affiliation_filter_term_attributes: {id: @user_record_filter.project_affiliation_filter_term.id, _destroy: 1}
      }
      assert_difference('ProjectAffiliationFilterTerm.count', -1) do
        patch :update, id: @user_record_filter, record_filter: change
      end
      assert_not_nil assigns(:record_filter)
      assert_equal @user_record_filter.id, assigns(:record_filter).id
      trf = RecordFilter.find(@user_record_filter.id)
      assert trf.project_affiliation_filter_term.nil?, 'project_affiliation_filter_term should now be removed'
    end

    should 'be able to update a record_filter to add an annotation_filter_terms_attribute' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      change = {
        annotation_filter_terms_attributes: [{term: 'random_test_term_a', context: 'random_test_context_a'}, {created_by: 3, term: 'random_test_term_b', context: 'random_test_context_b'}]
      }
      assert_difference('AnnotationFilterTerm.count', +change[:annotation_filter_terms_attributes].size) do
        patch :update, id: @user_record_filter, record_filter: change
      end
      assert_not_nil assigns(:record_filter)
      assert_equal @user_record_filter.id, assigns(:record_filter).id
      trf = RecordFilter.find(@user_record_filter.id)
      change[:annotation_filter_terms_attributes].each do |change|
        change_found = false
        trf.annotation_filter_terms.each do |aft|
          unless change_found
            if change[:term] == aft.term &&
               change[:context] == aft.context &&
               change[:created_by] == aft.created_by
              change_found = true
            end
          end
        end
        assert change_found, 'new annotation_filter_term should have been on the record_filter after update'
      end
    end

    should 'be able to update a record_filter to remove an annotation_filter_terms_attribute' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      assert @user_record_filter.annotation_filter_terms.count > 0, 'there should be some annotation_filter_terms on the record_filter'
      change = {
        annotation_filter_terms_attributes: @user_record_filter.annotation_filter_terms.collect{|aft| {id: aft.id, _destroy: 1}}
      }
      assert_difference('AnnotationFilterTerm.count', -@user_record_filter.annotation_filter_terms.count) do
        patch :update, id: @user_record_filter, record_filter: change
      end
      assert_not_nil assigns(:record_filter)
      assert_equal @user_record_filter.id, assigns(:record_filter).id
      trf = RecordFilter.find(@user_record_filter.id)
      assert trf.annotation_filter_terms.empty?, 'there should not be any annotation_filter_terms after update'
    end
  end

  def self.create_functionality()
    should 'be able to create a record_filter with a project_affiliation_filter_term' do
      assert_not_nil @user
      new_record_filter = {
        name: "TEST_#{@user.to_s}_FILTER",
        project_affiliation_filter_term_attributes: {project_id: 444}
      }
      assert_difference('RecordFilter.count') do
        assert_difference('ProjectAffiliationFilterTerm.count') do
          post :create, record_filter: new_record_filter
          assert assigns(:record_filter).errors.empty?, "#{ assigns(:record_filter).errors.inspect }"
        end
      end
      assert_redirected_to record_filters_path
      assert_not_nil assigns(:record_filter)
      assert_not_nil assigns(:record_filter).project_affiliation_filter_term
      assert_equal new_record_filter[:project_affiliation_filter_term_attributes][:project_id], assigns(:record_filter).project_affiliation_filter_term.project_id
    end

    should 'be able to create a record_filter with multiple annotation_filter_terms_attributes' do
      assert_not_nil @user
      new_record_filter = {
        name: "TEST_#{@user.to_s}_FILTER",
        annotation_filter_terms_attributes: [{term: 'random_test_term_a', context: 'random_test_context_a'}, {created_by: 3, term: 'random_test_term_b', context: 'random_test_context_b'}]
      }
      assert_difference('RecordFilter.count') do
        assert_difference('AnnotationFilterTerm.count', +new_record_filter[:annotation_filter_terms_attributes].size) do
          post :create, record_filter: new_record_filter
        end
      end
      assert_redirected_to record_filters_path
      assert_not_nil assigns(:record_filter)
      new_record_filter[:annotation_filter_terms_attributes].each do |change|
        change_found = false
        assigns(:record_filter).annotation_filter_terms.each do |aft|
          unless change_found
            if change[:term] == aft.term &&
               change[:context] == aft.context &&
               change[:created_by] == aft.created_by
              change_found = true
            end
          end
        end
        assert change_found, 'new annotation_filter_term should have been on the record_filter after update'
      end
    end
  end

  def self.destroy_functionality()
    should 'be able to destroy a record_filter and its project_affiliation_filter_term' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      assert_not_nil @user_record_filter.project_affiliation_filter_term
      assert_difference('RecordFilter.count', -1) do
        assert_difference('ProjectAffiliationFilterTerm.count',-1) do
          delete :destroy, id: @user_record_filter
        end
      end
      assert_not_nil assigns(:record_filter)
      assert !@user.record_filters.where(id: @user_record_filter.id).exists?, 'record_filter should no longer exist'
    end

    should 'be able to destroy a record_filter and its annotation_filter_terms' do
      assert_not_nil @user
      assert_not_nil @user_record_filter
      assert @user_record_filter.annotation_filter_terms.count > 0, 'there should be some annotation_filter_terms on the record_filter'
      assert_difference('RecordFilter.count', -1) do
        assert_difference('AnnotationFilterTerm.count',-@user_record_filter.annotation_filter_terms.count) do
          delete :destroy, id: @user_record_filter
        end
      end
      assert_not_nil assigns(:record_filter)
      assert !@user.record_filters.where(id: @user_record_filter.id).exists?, 'record_filter should no longer exist'
    end
  end

  context 'User not logged in' do
    should_not_get :index
    should_not_get :new

    should "not show record_fiilter" do
      @record_filter = record_filters(:model_test)
      get :show, id: @record_filter
      assert_redirected_to sessions_new_url(:target => record_filter_url(@record_filter))
    end

    should "not create project" do
      assert_no_difference('Project.count') do
        post :create, record_filter: { name: "TEST_not_logged_in_FILTER", filename: "shouldnotcreate.png"}
      end
      assert_redirected_to sessions_new_url(:target => record_filters_url(record_filter: {name: "TEST_not_logged_in_FILTER", filename: "shouldnotcreate.png"}))
    end

  end #User not logged in

  context 'Non Admin RepositoryUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @user_record_filters = @user.record_filters.all
      @user_record_filter = record_filters(:model_test)
      @other_user_record_filter = record_filters(:admin)
    end

    owned_by_user
    not_owned_by_user
    update_functionality
    create_functionality
    destroy_functionality
  end #Non Admin RepositoryUser

  context 'Admin RepositoryUser' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @user_record_filters = @user.record_filters.all
      @other_user_record_filter = record_filters(:non_admin)
    end

    owned_by_user
    not_owned_by_user
  end #Admin RepositoryUser

  context 'CoreUser' do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @user_record_filters = @user.record_filters.all
      @other_user_record_filter = record_filters(:non_admin)
    end

    owned_by_user
    not_owned_by_user
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @user_record_filters = @user.record_filters.all
      @other_user_record_filter = record_filters(:non_admin)
    end

    owned_by_user
    not_owned_by_user
  end #ProjectUser
end
