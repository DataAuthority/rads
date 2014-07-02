class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.integer :creator_id
      t.integer :record_id
      t.string :context
      t.string :term

      t.timestamps
    end
  end
end
