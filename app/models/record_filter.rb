class RecordFilter < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :name
  validates_uniqueness_of :name, scope: :user_id, allow_nil: true
  has_many :annotation_filter_terms, dependent: :destroy, inverse_of: :record_filter
  has_one :project_affiliation_filter_term, dependent: :destroy, inverse_of: :record_filter

  accepts_nested_attributes_for :annotation_filter_terms, allow_destroy: true
  accepts_nested_attributes_for :project_affiliation_filter_term, allow_destroy: true

  def query(relation)
    unless record_created_by.nil?
      relation = relation.where(creator_id: record_created_by)
    end

    unless is_destroyed.nil?
      relation = relation.where(is_destroyed: is_destroyed)
    end

    if created_on.nil?
      #created_on takes precendence over these
      if created_after && created_before
        #range query = BETWEEN
        relation = relation.where(created_at: created_before.to_time.end_of_day..created_after.to_time.beginning_of_day)
      elsif created_after
        relation = relation.where('created_at > ?', created_after.to_time.end_of_day)
      elsif created_before
        relation = relation.where('created_at < ?', created_before.to_time.beginning_of_day)
      else
        # do nothing
      end
    else
      relation = relation.where(created_at: created_on.to_time.beginning_of_day..created_on.to_time.end_of_day)
    end

    unless filename.nil?
      # support glob searches
      if filename.match '\*'
        relation = relation.where('content_file_name like ?', filename.gsub('*','%'))
      else
        relation = relation.where(content_file_name: filename)
      end
    end

    unless file_content_type.nil?
      relation = relation.where(content_content_type: file_content_type)
    end

    if file_size.nil?
      #file_size takes precedence over these
      if file_size_greater_than && file_size_less_than
        relation = relation.where(content_file_size: file_size_greater_than..file_size_less_than)
      elsif file_size_greater_than
        relation = relation.where(content_file_size: file_size_greater_than)
      elsif file_size_less_than
        relation = relation.where(content_file_size: file_size_less_than)
      else
        # do nothing
      end
    else
      relation = relation.where(content_file_size: file_size)
    end

    unless file_md5hashsum.nil?
      relation = relation.where(content_fingerprint: file_md5hashsum)
    end

    unless project_affiliation_filter_term.nil?
      relation = project_affiliation_filter_term.query(relation)
    end

    annotation_filter_terms.each do |aft|
      relation = aft.query(relation)
    end

    relation
  end

  def query_parameters
    qp = {}

    unless record_created_by.nil?
      qp[:record_created_by] = record_created_by
    end

    unless is_destroyed.nil?
      qp[:is_destroyed] = is_destroyed
    end

    unless created_on.nil?
      qp[:created_on] = created_on
    end

    unless created_after.nil?
      qp[:created_after] = created_after
    end
      
    unless created_before.nil?
      qp[:created_before] = created_before
    end
    
    unless filename.nil?
      qp[:filename] = filename
    end

    unless file_content_type.nil?
      qp[:file_content_type] = file_content_type
    end

    unless file_size.nil?
      qp[:file_size] = file_size
    end

    unless file_size_greater_than.nil?
      qp[:file_size_greater_than] = file_size_greater_than
    end

    unless file_size_less_than.nil?
      qp[:file_size_less_than] = file_size_less_than
    end

    unless file_md5hashsum.nil?
      qp[:file_md5hashsum] = file_md5hashsum
    end

    unless project_affiliation_filter_term.nil?
      qp[:project_affiliation_filter_term_attributes] = project_affiliation_filter_term.query_parameters
    end

    if annotation_filter_terms.count > 0
      qp[:annotation_filter_terms_attributes] = annotation_filter_terms.collect {|aft| aft.query_parameters}
    end

    {record_filter: qp}
  end
end
