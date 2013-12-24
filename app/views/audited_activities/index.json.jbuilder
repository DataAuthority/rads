json.array!(@audited_activities) do |audited_activity|
  json.extract! audited_activity, :authenticated_user_id, :current_user_id, :controller_name, :http_method, :action, :params, :record_id
  json.url audited_activity_url(audited_activity, format: :json)
end
