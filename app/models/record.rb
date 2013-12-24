class Record < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  has_many :project_affiliated_records, inverse_of: :affiliated_record
  has_many :audited_activities

  has_attached_file :content, path: ":interpolated_path"

  scope :find_by_md5, ->(md5) {where(content_fingerprint: md5)}

  def to_s
    "#{content_file_name} (#{created_at})"
  end

  private

  Paperclip.interpolates :interpolated_path do |attachment, style|
    [ attachment.instance.creator.storage_path, attachment.instance.id, attachment.instance.content_file_name].join('/')
  end
end
