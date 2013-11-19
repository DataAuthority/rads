class CreateCoreMemberships < ActiveRecord::Migration
  def change
    create_table :core_memberships do |t|
      t.integer :core_id
      t.integer :repository_user_id

      t.timestamps
    end
  end
end
