json.array!(@users) do |user|
  json.extract! user, :name, :type, :email, :netid
  json.url user_url(user, format: :json)
end
