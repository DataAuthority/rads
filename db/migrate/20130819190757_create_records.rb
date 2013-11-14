class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.integer :creator_id
      t.boolean :is_destroyed

      t.timestamps
    end
  end
end
