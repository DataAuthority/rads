json.array!(@records) do |record|
  json.extract! record, :creator_id, :is_destroyed
  json.url record_url(record, format: :json)
end
