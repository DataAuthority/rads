class Core < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  has_many :core_memberships, inverse_of: :core
  has_one :core_user

  validates_presence_of :name
  validates_presence_of :creator_id

  def is_member?(repository_user)
    core_memberships.where(repository_user_id: repository_user.id).exists?
  end
end
