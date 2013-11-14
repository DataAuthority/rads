json.array!(@repository_users) do |repository_user|
  json.extract! repository_user, 
  json.url repository_user_url(repository_user, format: :json)
end
