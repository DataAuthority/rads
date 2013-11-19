class CoreMembership < ActiveRecord::Base
  belongs_to :core
  belongs_to :repository_user
  validates_presence_of :repository_user_id
end
