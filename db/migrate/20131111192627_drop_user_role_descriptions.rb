class DropUserRoleDescriptions < ActiveRecord::Migration
  def change
    drop_table :user_role_descriptions do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
