class CreateCartRecords < ActiveRecord::Migration
  def change
    create_table :cart_records do |t|
      t.integer :record_id
      t.integer :user_id

      t.timestamps
    end
  end
end
