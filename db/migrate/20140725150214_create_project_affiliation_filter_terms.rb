class CreateProjectAffiliationFilterTerms < ActiveRecord::Migration
  def change
    create_table :project_affiliation_filter_terms do |t|
      t.references :record_filter, index: true
      t.integer :project_id

      t.timestamps
    end
  end
end
