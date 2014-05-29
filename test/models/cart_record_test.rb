require 'test_helper'

class CartRecordTest < ActiveSupport::TestCase
  should belong_to :user
  should belong_to :stored_record
  should validate_presence_of :record_id
  should validate_uniqueness_of(:record_id).scoped_to(:user_id)

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, CartRecord, [:index] )
      denied_abilities(nil, cart_records(:user), [:destroy])
      denied_abilities(nil, cart_records(:other_user), [:destroy])
      denied_abilities(nil, CartRecord.new, [:create])
    end
  end #nil user

  context 'logged in user' do
    setup do
      @user = users(:non_admin)
      @other_user = users(:admin)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, CartRecord, [:index])
      allowed_abilities(@user, cart_records(:user), [:destroy])
      denied_abilities(@user, cart_records(:other_user), [:destroy])
      allowed_abilities(@user, CartRecord.new(user_id: @user.id, record_id: records(:user).id), [:create])
      denied_abilities(@user, CartRecord.new(user_id: @other_user.id, record_id: records(:user).id), [:create])

      unreadable_record = records(:core_user)
      denied_abilities(@user, unreadable_record, [:read])
      denied_abilities(@user, CartRecord.new(user_id: @user.id, record_id: unreadable_record.id), [:create])
      denied_abilities(@user, CartRecord.new(user_id: @other_user.id, record_id: unreadable_record.id), [:create])
    end
  end
end
