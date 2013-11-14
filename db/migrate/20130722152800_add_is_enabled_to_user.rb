class AddIsEnabledToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_enabled, :boolean
  end
end
