class CreateAgents < ActiveRecord::Migration
  def change
    create_table :agents do |t|
      t.string :name
      t.string :description
      t.string :api_token
      t.boolean :is_disabled
      t.string :homepage
      t.string :docker_registry_url
      t.integer :creator_id

      t.timestamps
    end
  end
end
