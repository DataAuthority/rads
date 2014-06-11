class AddRolesToProjectMembership < ActiveRecord::Migration
  def change
    add_column :project_memberships, :is_administrator, :boolean
    add_column :project_memberships, :is_data_producer, :boolean
    add_column :project_memberships, :is_data_consumer, :boolean
    add_column :project_memberships, :is_data_manager, :boolean
  end
end
