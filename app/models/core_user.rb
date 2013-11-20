class CoreUser < User
  belongs_to :core
  validates_presence_of :core_id
end
