class RepositoryUser < User
  has_many :core_memberships
  has_many :cores, through: :core_memberships
  validates_presence_of :netid
end
