require 'test_helper'

class AuditedActivityTest < ActiveSupport::TestCase
  should belong_to(:current_user).class_name('User')
  should belong_to(:authenticated_user).class_name('User')
  should belong_to :record

  should validate_presence_of :current_user_id
  should validate_presence_of :authenticated_user_id
  should validate_presence_of :controller_name
  should validate_presence_of :http_method
  should validate_presence_of :action
  should validate_presence_of :params

  should ensure_inclusion_of(:http_method).in_array(%w{get post patch delete})
end
