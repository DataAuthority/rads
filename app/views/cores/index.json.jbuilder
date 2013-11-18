json.array!(@cores) do |core|
  json.extract! core, :name, :description, :creator_id
  json.url core_url(core, format: :json)
end
