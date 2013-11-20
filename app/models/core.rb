class Core < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
<<<<<<< HEAD
  has_many :core_memberships, inverse_of: :core
=======
  has_many :core_memberships
  has_one :core_user
>>>>>>> 6e649ae9a75d46827c9fb60c1267ca3447306144

  validates_presence_of :name
  validates_presence_of :creator_id
end
