class CreateAnnotationFilterTerms < ActiveRecord::Migration
  def change
    create_table :annotation_filter_terms do |t|
      t.references :record_filter, index: true
      t.integer :created_by
      t.string :term
      t.string :context

      t.timestamps
    end
  end
end
