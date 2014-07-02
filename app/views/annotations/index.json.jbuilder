json.array!(@annotations) do |annotation|
  json.extract! annotation, :id, :creator_id, :record_id, :context, :term
  json.url annotation_url(annotation, format: :json)
end
