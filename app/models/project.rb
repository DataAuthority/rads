class Project < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  validates_presence_of :name
  validates_presence_of :creator_id

  def to_s
    name
  end
end
