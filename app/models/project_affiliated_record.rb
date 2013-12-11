class ProjectAffiliatedRecord < ActiveRecord::Base
  belongs_to :project
  belongs_to :affiliated_record, class_name: 'Record', foreign_key: 'record_id'
  validates_presence_of :project_id
  validates_presence_of :affiliated_record
end
