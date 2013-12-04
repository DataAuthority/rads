class Project < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  validates_presence_of :name
  validates_presence_of :creator_id
  has_many :project_memberships, inverse_of: :project
  has_one :project_user, inverse_of: :project

  def to_s
    name
  end

  def is_member?(user)
    project_memberships.where(user_id: user.id).exists?
  end
end
