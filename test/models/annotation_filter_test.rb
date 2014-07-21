require 'test_helper'

class AnnotationFilterTest < ActiveSupport::TestCase
  should allow_value(true).for(:creator_id)
  should_respond_to(:creator_id)
  should_respond_to(:creator_id?)

  should allow_value(true).for(:record_id)
  should_respond_to(:record_id)
  should_respond_to(:record_id?)

  should allow_value(true).for(:context)
  should_respond_to(:context)
  should_respond_to(:context?)

  should allow_value(true).for(:term)
  should_respond_to(:term)
  should_respond_to(:term?)
end
