class ProjectAffiliationFilterTerm < ActiveRecord::Base
  belongs_to :record_filter
  validates_presence_of :record_filter
  validates_presence_of :project_id

  def query(relation, join_name)
    relation = relation.joins("INNER JOIN project_affiliated_records #{ join_name } on records.id = #{ join_name }.record_id").where(Hash[join_name, {project_id: project_id}])
    relation
  end

  def query_parameters
    {project_id: project_id}
  end
end
