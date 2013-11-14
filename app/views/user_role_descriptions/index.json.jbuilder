json.array!(@user_role_descriptions) do |user_role_description|
  json.extract! user_role_description, :name, :description
  json.url user_role_description_url(user_role_description, format: :json)
end
