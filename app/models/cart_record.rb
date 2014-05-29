class CartRecord < ActiveRecord::Base
  belongs_to :user
  belongs_to :stored_record, class_name: 'Record', foreign_key: 'record_id'

  validates_presence_of :record_id
  validates_uniqueness_of :record_id, scope: :user_id
end
