class AddAttachmentContentToRecords < ActiveRecord::Migration
  def self.up
    change_table :records do |t|
      t.attachment :content
    end
    add_column :records, :content_fingerprint, :string
  end

  def self.down
    drop_attached_file :records, :content
    remove_column :records, :content_fingerprint
  end
end
