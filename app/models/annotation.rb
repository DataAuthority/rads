class Annotation < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  belongs_to :annotated_record, class_name: 'Record', foreign_key: 'record_id'
  validates_presence_of :creator_id
  validates_presence_of :annotated_record
  validates_presence_of :term
  validates_uniqueness_of :term, scope: [:creator_id, :record_id, :context], allow_nil: true,
                          message: "already applied to record in this context, try a different context"

  def to_s
    context && !context.empty? ? "#{context}:#{term}" : term
  end
end
