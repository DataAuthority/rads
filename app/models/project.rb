class Project < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  validates_presence_of :name
  validates_presence_of :creator_id
  has_many :project_memberships, inverse_of: :project
  has_one :project_user, inverse_of: :project
  has_many :project_affiliated_records, inverse_of: :project
  has_many :records, through: :project_affiliated_records, source: :affiliated_record
  accepts_nested_attributes_for :project_affiliated_records, allow_destroy: true
  accepts_nested_attributes_for :project_memberships, allow_destroy: true

  def to_s
    name
  end

  def is_member?(user)
    project_memberships.where(user_id: user.id).exists?
  end

  def is_affiliated_record?(record)
    project_affiliated_records.where(record_id: record.id).exists?
  end
end
