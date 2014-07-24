class Cart
  include ActiveModel::Model

  attr_accessor :action, :project_id, :context, :term

  def actions
    %w{destroy_records affiliate_to_project annotate}
  end
end
