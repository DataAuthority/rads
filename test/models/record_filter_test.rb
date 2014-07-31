require 'test_helper'

class RecordFilterTest < ActiveSupport::TestCase
  def self.test_abilities()
    should 'be able to manage their own record_filters but not other users record_filters' do
      assert_not_nil @user
      assert_not_nil @other_user
      assert @user.id != @other_user.id, 'user and other_user should be different'
      assert_not_nil @user_record_filter
      assert_equal @user.id, @user_record_filter.user_id
      assert_not_nil @other_user_record_filter
      assert @user.id != @other_user_record_filter.user_id, 'user should not have created other_user_record_filter'

      allowed_abilities(@user, @user_record_filter, [:index, :destroy])
      allowed_abilities(@user, RecordFilter.new(user_id: @user.id), [:create])
      denied_abilities(@user, RecordFilter.new(user_id: @other_user.id), [:create])
      denied_abilities(@user, @other_user_record_filter, [:index, :destroy])
    end    
  end

  should belong_to :user
  should validate_presence_of :user_id
  should validate_presence_of :name
  should validate_uniqueness_of(:name).scoped_to(:user_id)

  should have_one(:project_affiliation_filter_term).dependent(:destroy)
  should have_many(:annotation_filter_terms).dependent(:destroy)
  should accept_nested_attributes_for :project_affiliation_filter_term
  should accept_nested_attributes_for :annotation_filter_terms

  setup do
    @record_filter = record_filters(:model_test)
  end

  should 'have a name attribute' do
    assert_respond_to @record_filter, 'name'
    assert_instance_of String, @record_filter.name
  end

  should 'have a record_created_by attribute' do
    assert_respond_to @record_filter, 'record_created_by'
    assert_kind_of Integer, @record_filter.record_created_by
  end

  should 'have a is_destroyed attribute' do
    assert_respond_to @record_filter, 'is_destroyed'
  end

  should 'have a record_created_on attribute' do
    assert_respond_to @record_filter, 'record_created_on'
    assert_instance_of Date, @record_filter.record_created_on
  end

  should 'have a record_created_after attribute' do
    assert_respond_to @record_filter, 'record_created_after'
    assert_instance_of Date, @record_filter.record_created_after
  end

  should 'have a record_created_before attribute' do
    assert_respond_to @record_filter, 'record_created_before'
    assert_instance_of Date, @record_filter.record_created_before
  end

  should 'have a filename attribute' do
    assert_respond_to @record_filter, 'filename'
    assert_instance_of String, @record_filter.filename
  end

  should 'have a file_content_type attribute' do
    assert_respond_to @record_filter, 'file_content_type'
    assert_instance_of String, @record_filter.file_content_type
  end

  should 'have a file_md5hashsum attribute' do
    assert_respond_to @record_filter, 'file_md5hashsum'
    assert_instance_of String, @record_filter.file_md5hashsum
  end

  should 'have a file_size attribute' do
    assert_respond_to @record_filter, 'file_size'
    assert_kind_of Integer, @record_filter.file_size
  end

  should 'have a file_size_less_than attribute' do
    assert_respond_to @record_filter, 'file_size_less_than'
    assert_kind_of Integer, @record_filter.file_size_less_than
  end

  should 'have a file_size_greater_than attribute' do
    assert_respond_to @record_filter, 'file_size_greater_than'
    assert_kind_of Integer, @record_filter.file_size_greater_than
  end

  should 'support query method, which takes an Record::ActiveRecord_Relation, updates it based on its state, and returns the updated Record::ActiveRecord_Relation' do
    assert_respond_to @record_filter, 'query'
    q = Record.all
    assert_instance_of Record::ActiveRecord_Relation, q
    new_q = @record_filter.query(q)
    assert_instance_of Record::ActiveRecord_Relation, new_q
    assert q != new_q, 'q and new_q shuold be different'
  end

  should 'support query_parameters method which returns a Hash of URL query parameters' do
    assert_respond_to @record_filter, 'query_parameters'
    q_params = @record_filter.query_parameters
    assert_not_nil q_params
    assert_instance_of Hash, q_params
    assert_includes q_params.keys, :record_filter
    record_filter_params = q_params[:record_filter]
    assert_not_nil record_filter_params
    assert_instance_of Hash, record_filter_params
    assert_includes record_filter_params.keys, :record_created_by
    assert_equal @record_filter.record_created_by, record_filter_params[:record_created_by]
    assert_includes record_filter_params.keys, :is_destroyed
    assert_equal @record_filter.is_destroyed, record_filter_params[:is_destroyed]
    assert_includes record_filter_params.keys, :record_created_on
    assert_equal @record_filter.record_created_on, record_filter_params[:record_created_on]
    assert_includes record_filter_params.keys, :record_created_after
    assert_equal @record_filter.record_created_after, record_filter_params[:record_created_after]
    assert_includes record_filter_params.keys, :record_created_before
    assert_equal @record_filter.record_created_before, record_filter_params[:record_created_before]
    assert_includes record_filter_params.keys, :filename
    assert_equal @record_filter.filename, record_filter_params[:filename]
    assert_includes record_filter_params.keys, :file_content_type
    assert_equal @record_filter.file_content_type, record_filter_params[:file_content_type]
    assert_includes record_filter_params.keys, :file_size
    assert_equal @record_filter.file_size, record_filter_params[:file_size]
    assert_includes record_filter_params.keys, :file_size_less_than
    assert_equal @record_filter.file_size_less_than, record_filter_params[:file_size_less_than]
    assert_includes record_filter_params.keys, :file_size_greater_than
    assert_equal @record_filter.file_size_greater_than, record_filter_params[:file_size_greater_than]
    assert_includes record_filter_params.keys, :file_md5hashsum
    assert_equal @record_filter.file_md5hashsum, record_filter_params[:file_md5hashsum]
    assert_includes record_filter_params.keys, :annotation_filter_terms_attributes

    assert @record_filter.annotation_filter_terms.count > 1, 'there should be some annotation_filter_terms'
    annotation_filter_terms_attributes = record_filter_params[:annotation_filter_terms_attributes]
    assert_not_nil annotation_filter_terms_attributes
    assert_instance_of Array, annotation_filter_terms_attributes
    assert_equal @record_filter.annotation_filter_terms.count, annotation_filter_terms_attributes.size
    @record_filter.annotation_filter_terms.each do |aft|
      found = false
      annotation_filter_terms_attributes.each do |afth|
        unless found
          found = ( (afth[:created_by] == aft.created_by) && (afth[:term] == aft.term) && (afth[:context] == aft.context) )
        end
      end
      assert found, 'annotation_term should be found'
    end

    project_affiliation_filter_term = @record_filter.project_affiliation_filter_term
    assert_not_nil project_affiliation_filter_term
    assert_includes record_filter_params.keys, :project_affiliation_filter_term_attributes
    project_affiliation_filter_term_attributes = record_filter_params[:project_affiliation_filter_term_attributes]
    assert_not_nil project_affiliation_filter_term_attributes
    assert_instance_of Hash, project_affiliation_filter_term_attributes
    assert_equal project_affiliation_filter_term.project_id, project_affiliation_filter_term_attributes[:project_id]
  end

  context 'Non Admin' do
    setup do
      @user = users(:non_admin)
      @user_record_filter = record_filters(:non_admin)
      @other_user = users(:admin)
      @other_user_record_filter = record_filters(:admin)
    end

    test_abilities
  end

  context 'Admin' do
    setup do
      @user = users(:admin)
      @user_record_filter = record_filters(:admin)
      @other_user = users(:non_admin)
      @other_user_record_filter = record_filters(:non_admin)
    end

    test_abilities
  end

  context 'CoreUser' do
    setup do
      @user = users(:core_user)
      @user_record_filter = record_filters(:core_user)
      @other_user = users(:admin)
      @other_user_record_filter = record_filters(:admin)
    end

    test_abilities
  end

  context 'ProjectUser' do
    setup do
      @user = users(:project_user)
      @user_record_filter = record_filters(:project_user)
      @other_user = users(:admin)
      @other_user_record_filter = record_filters(:admin)
    end

    test_abilities
  end
end
