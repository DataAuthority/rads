class Core < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  has_many :core_memberships
  has_one :core_user

  validates_presence_of :name
  validates_presence_of :creator_id
end
