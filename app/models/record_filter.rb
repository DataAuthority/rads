# -*- coding: utf-8 -*-
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

    if is_destroyed
      relation = relation.where(is_destroyed: is_destroyed?)
    end

    if record_created_on.nil?
      #record_created_on takes precendence over these
      if record_created_after && record_created_before
        #range query = BETWEEN
        relation = relation.where(created_at: record_created_after.to_time.end_of_day..record_created_before.to_time.beginning_of_day)
      elsif record_created_after
        relation = relation.where('records.created_at > ?', record_created_after.to_time.end_of_day)
      elsif record_created_before
        relation = relation.where('records.created_at < ?', record_created_before.to_time.beginning_of_day)
      else
        # do nothing
      end
    else
      relation = relation.where(created_at: record_created_on.to_time.beginning_of_day..record_created_on.to_time.end_of_day)
    end

    unless filename.nil? || filename.empty?
      # support glob searches
      if filename.match '\*'
        relation = relation.where('content_file_name like ?', filename.gsub('*','%'))
      else
        relation = relation.where(content_file_name: filename)
      end
    end

    unless file_content_type.nil? || file_content_type.empty?
      relation = relation.where(content_content_type: file_content_type)
    end

    if file_size.nil?
      #file_size takes precedence over these
      if file_size_greater_than && file_size_less_than
        relation = relation.where(content_file_size: file_size_greater_than+1..file_size_less_than-1)
      elsif file_size_greater_than
        relation = relation.where('records.content_file_size > ?', file_size_greater_than)
      elsif file_size_less_than
        relation = relation.where('records.content_file_size < ?', file_size_less_than)
      else
        # do nothing
      end
    else
      relation = relation.where(content_file_size: file_size)
    end

    unless file_md5hashsum.nil? || file_md5hashsum.empty?
      relation = relation.where(content_fingerprint: file_md5hashsum)
    end

    unless project_affiliation_filter_term.nil?
      relation = project_affiliation_filter_term.query(relation, 'par')
    end

    annotation_filter_terms.each_with_index do |aft, i|
      relation = aft.query(relation, "aft_#{ i }")
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

    unless record_created_on.nil?
      qp[:record_created_on] = record_created_on
    end

    unless record_created_after.nil?
      qp[:record_created_after] = record_created_after
    end
      
    unless record_created_before.nil?
      qp[:record_created_before] = record_created_before
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
