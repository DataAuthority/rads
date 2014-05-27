json.array!(@cart_records) do |cart_record|
  json.extract! cart_record, :id, :record_id, :user_id
  json.url cart_record_url(cart_record, format: :json)
end
