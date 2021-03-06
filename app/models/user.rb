class User < ActiveRecord::Base
  attr_accessor :acting_on_behalf_of

  has_many :records, foreign_key: :creator_id
  has_many :project_memberships
  has_many :projects, through: :project_memberships
  has_many :audited_activities, foreign_key: :authenticated_user_id
  has_many :cart_records
  has_many :record_filters
  has_many :annotations, foreign_key: :creator_id
  has_many :agents, foreign_key: :creator_id

  def register_login_client(client)
    self.last_login_client = client
    self.last_login_time = Time.now
  end

  def to_s
    name
  end
  def storage_path
    "#{ Rails.application.config.primary_storage_root }/#{ id }" if id
  end
end
