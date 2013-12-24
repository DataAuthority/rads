class CreateAuditedActivities < ActiveRecord::Migration
  def change
    create_table :audited_activities do |t|
      t.integer :authenticated_user_id
      t.integer :current_user_id
      t.string :controller_name
      t.string :http_method
      t.string :action
      t.text :params
      t.integer :record_id

      t.timestamps
    end
  end
end
