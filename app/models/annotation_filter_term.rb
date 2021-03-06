class AnnotationFilterTerm < ActiveRecord::Base
  belongs_to :record_filter
  validates_presence_of :record_filter

  def query(relation, join_name)
    if (term.nil? || term.empty?) && (context.nil? or context.empty?) && created_by.nil?
      return relation
    end
    where_clause = {}
    unless term.nil? || term.empty?
      where_clause[:term] = term
    end

    unless created_by.nil?
      where_clause[:creator_id] = created_by
    end

    # if they want term across All contexts, including nil, do not include context in the query
    unless context == '_ALL_'
      # if they do not specify context, or specify context as nil, or specify a context, include
      #  context in the query to return only term with specified context, which might be nil
      where_clause[:context] = context
    end
    unless where_clause.empty?
      relation = relation.joins("INNER JOIN annotations #{ join_name } on records.id = #{ join_name }.record_id").where(Hash[join_name, where_clause])
    end
    relation
  end

  def query_parameters
    ret = {}
    unless term.nil?
      ret[:term] = term
    end
    unless created_by.nil?
      ret[:created_by] = created_by
    end
    unless context.nil?
      ret[:context] = context
    end
    ret
  end

end
