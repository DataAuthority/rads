class AnnotationFilter
  include ActiveModel::Model

  attr_accessor :creator_id,
    :record_id,
    :context,
    :term

  def creator_id?
    creator_id && !creator_id.blank?
  end

  def record_id?
    record_id && !record_id.blank?
  end

  def context?
    context && !context.blank?
  end

  def term?
    term && !term.blank?
  end
end
