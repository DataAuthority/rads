class AnnotationFilterTerm < ActiveRecord::Base
  belongs_to :record_filter
  validates_presence_of :record_filter
  validates_presence_of :term

  def query(relation)
    where_clause = {term: term}
    unless created_by.nil?
      where_clause[:created_by] = created_by
    end

    # if they want term across All contexts, including nil, do not include context in the query
    unless context == 'All'
      # if they do not specify context, or specify context as nil, or specify a context, include
      #  context in the query to return only term with specified context, which might be nil
      where_clause[:context] = context
    end    
    relation.joins(:annotations).where(where_clause)
  end

  def query_parameters
    ret = {term: term}
    unless created_by.nil?
      ret[:created_by] = created_by
    end
    unless context.nil?
      ret[:context] = context
    end
    ret
  end

end
