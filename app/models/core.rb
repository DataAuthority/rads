class Core < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  has_many :core_memberships, inverse_of: :core

  validates_presence_of :name
  validates_presence_of :creator_id
end
