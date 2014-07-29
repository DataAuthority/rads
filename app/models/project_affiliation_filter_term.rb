class ProjectAffiliationFilterTerm < ActiveRecord::Base
  belongs_to :record_filter
  validates_presence_of :record_filter
  validates_presence_of :project_id

  def query(relation)
    relation.joins(:projects).where(id: project_id)
  end

  def query_parameters
    {project_id: project_id}
  end
end
