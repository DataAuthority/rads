class AddCoreIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :core_id, :integer
  end
end
