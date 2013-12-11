class CreateProjectAffiliatedRecords < ActiveRecord::Migration
  def change
    create_table :project_affiliated_records do |t|
      t.integer :project_id
      t.integer :record_id

      t.timestamps
    end
  end
end
