json.array!(@project_affiliated_records) do |project_affiliated_record|
  json.extract! project_affiliated_record, :project_id, :record_id
  json.url project_project_affiliated_record_url(project_affiliated_record.project, project_affiliated_record, format: :json)
end
