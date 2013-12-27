require 'test_helper'

class AuditedActivityTest < ActiveSupport::TestCase
  should belong_to(:current_user).class_name('User')
  should belong_to(:authenticated_user).class_name('User')

  should validate_presence_of :current_user_id
  should validate_presence_of :authenticated_user_id
  should validate_presence_of :controller_name
  should validate_presence_of :http_method
  should validate_presence_of :action
  should validate_presence_of :params

  should ensure_inclusion_of(:http_method).in_array(%w{get post patch delete})

  setup do
    @audited_activity = audited_activities(:one)
  end

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, AuditedActivity, [:index] )
      denied_abilities(nil, @audited_activity, [:show])
    end
  end #nil user
  
  context 'non_admin' do
    should 'pass ability profile' do
      user = users(:non_admin)
      denied_abilities(user, AuditedActivity, [:index] )
      denied_abilities(user, @audited_activity, [:show])
    end
  end #non_admin

  context 'admin' do
    should 'pass ability profile' do
      user = users(:admin)
      allowed_abilities(user, AuditedActivity, [:index] )
      allowed_abilities(user, @audited_activity, [:show])
    end
  end #admin
end
