json.array!(@record_filters) do |record_filter|
  json.extract! record_filter, :id, :name, :created_by_user, :is_destroyed, :created_on, :created_after, :created_before, :filename, :file_content_type, :file_size, :file_size_less_than, :file_size_greater_than, :file_md5hashsum
  json.url record_filter_url(record_filter, format: :json)
end
