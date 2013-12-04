class ProjectUser < User
  belongs_to :project
  validates_presence_of :project
end
