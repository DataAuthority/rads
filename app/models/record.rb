class Record < ActiveRecord::Base

  belongs_to :creator, class_name: 'User'
  has_attached_file :content, path: ":interpolated_path"

  scope :find_by_md5, ->(md5) {where(content_fingerprint: md5)}

  private

  Paperclip.interpolates :interpolated_path do |attachment, style|
    [ attachment.instance.creator.storage_path, attachment.instance.id, attachment.instance.content_file_name].join('/')
  end
end
