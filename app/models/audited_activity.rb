class AuditedActivity < ActiveRecord::Base
  belongs_to :current_user, class_name: 'User'
  belongs_to :authenticated_user, class_name: 'User'

  validates_presence_of :current_user_id
  validates_presence_of :authenticated_user_id
  validates_presence_of :controller_name
  validates_presence_of :http_method
  validates_presence_of :action
  validates_presence_of :params

  validates :http_method, inclusion: {in: %w{get post patch delete}}
end
