class ProjectAffiliatedRecord < ActiveRecord::Base
  belongs_to :project
  belongs_to :affiliated_record, class_name: 'Record', foreign_key: 'record_id'
  validates_presence_of :project
  validates_presence_of :affiliated_record
  validates_uniqueness_of :project_id, scope: :record_id,
                          message: "record is already affiliated with this project"

  def to_s
    affiliated_record.to_s
  end
end
