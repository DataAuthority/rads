class User < ActiveRecord::Base
  has_many :records, foreign_key: :creator_id

  def to_s
    name
  end
  def storage_path
    "#{ Rails.application.config.primary_storage_root }/#{ id }" if id
  end
end
