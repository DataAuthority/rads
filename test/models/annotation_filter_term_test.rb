require 'test_helper'

class AnnotationFilterTermTest < ActiveSupport::TestCase
  should belong_to :record_filter
  should validate_presence_of :record_filter

  setup do
    @annotation_filter_term = annotation_filter_terms(:model_test_one)
  end

  should 'have a created_by attribute' do
    assert_respond_to @annotation_filter_term, 'created_by'
    assert_kind_of Integer, @annotation_filter_term.created_by
  end

  should 'have a created_by attribute' do
    assert_respond_to @annotation_filter_term, 'term'
    assert_instance_of String, @annotation_filter_term.term
  end

  should 'have a context attribute' do
    assert_respond_to @annotation_filter_term, 'context'
    assert_instance_of String, @annotation_filter_term.context
  end

  should 'support query method which takes an Record::ActiveRecord_Relation and a join_name, updates it based on its state to join annotations on the join_name, and returns the updated Record::ActiveRecord_Relation' do
    assert_respond_to @annotation_filter_term, 'query'
    q = Record.all
    assert_instance_of Record::ActiveRecord_Relation, q
    join_name = "annotation_1"
    new_q = @annotation_filter_term.query(q, join_name)
    assert_instance_of Record::ActiveRecord_Relation, new_q
    assert new_q.to_sql.match(join_name), "#{ new_q.to_sql } does not contain the #{ join_name }"
  end

  should 'support query_parameters method which returns a Hash of URL query parameters' do
    assert_respond_to @annotation_filter_term, 'query_parameters'
    q_params = @annotation_filter_term.query_parameters
    assert_instance_of Hash, q_params
    assert_equal @annotation_filter_term.created_by, q_params[:created_by]
    assert_equal @annotation_filter_term.term, q_params[:term]
    assert_equal @annotation_filter_term.context, q_params[:context]
  end
end
