class CreateRecordFilters < ActiveRecord::Migration
  def change
    create_table :record_filters do |t|
      t.integer :user_id
      t.string :name
      t.integer :record_created_by
      t.boolean :is_destroyed
      t.date :created_on
      t.date :created_after
      t.date :created_before
      t.string :filename
      t.string :file_content_type
      t.integer :file_size
      t.integer :file_size_less_than
      t.integer :file_size_greater_than
      t.string :file_md5hashsum

      t.timestamps
    end
  end
end
