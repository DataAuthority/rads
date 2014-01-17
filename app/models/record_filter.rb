class RecordFilter
  include ActiveModel::Model

  attr_accessor :affiliated_with_project

  def affiliated_with_project?
    affiliated_with_project && !affiliated_with_project.blank?
  end
end
