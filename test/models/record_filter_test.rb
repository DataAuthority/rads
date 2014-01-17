require 'test_helper'

class RecordFilterTest < ActiveSupport::TestCase
  should allow_value(true).for(:affiliated_with_project)
  should_respond_to(:affiliated_with_project)
  should_respond_to(:affiliated_with_project?)
end
