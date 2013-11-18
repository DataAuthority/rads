class CreateCores < ActiveRecord::Migration
  def change
    create_table :cores do |t|
      t.string :name
      t.text :description
      t.integer :creator_id

      t.timestamps
    end
  end
end
