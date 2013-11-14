class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.integer :user_role_description_id
      t.integer :user_id

      t.timestamps
    end
  end
end
