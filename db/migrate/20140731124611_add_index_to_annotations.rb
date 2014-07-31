class AddIndexToAnnotations < ActiveRecord::Migration
  def change
    add_index :annotations, :context
    add_index :annotations, :term
  end
end
