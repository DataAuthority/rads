class Cart
  include ActiveModel::Model

  attr_accessor :action, :project_id

  def actions
    %w{destroy_records affiliate_to_project}
  end
end
