require 'test_helper'

class ProjectAffiliationFilterTermTest < ActiveSupport::TestCase
  should belong_to :record_filter
  should validate_presence_of :record_filter
  should validate_presence_of :project_id

  setup do
    @project_affiliation_filter_term = project_affiliation_filter_terms(:model_test)
  end

  should 'have a created_by attribute' do
    assert_respond_to @project_affiliation_filter_term, 'project_id'
    assert_kind_of Integer, @project_affiliation_filter_term.project_id
  end

  should 'support query method which takes an Record::ActiveRecord_Relation, updates it based on its state, and returns the updated Record::ActiveRecord_Relation' do
    assert_respond_to @project_affiliation_filter_term, 'query'
    q = Record.all
    assert_instance_of Record::ActiveRecord_Relation, q
    new_q = @project_affiliation_filter_term.query(q)
    assert_instance_of Record::ActiveRecord_Relation, new_q
    assert q != new_q, 'q and new_q shuold be different'
  end

  should 'support query_parameters method which returns a Hash of URL query parameters' do
    assert_respond_to @project_affiliation_filter_term, 'query_parameters'
    q_params = @project_affiliation_filter_term.query_parameters
    assert_instance_of Hash, q_params
    assert_equal @project_affiliation_filter_term.project_id, q_params[:project_id]
  end
end
