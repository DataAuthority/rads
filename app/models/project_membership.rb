class ProjectMembership < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  validates_presence_of :project
  validates_presence_of :user_id
  validates_uniqueness_of :project_id, scope: :user_id
end
