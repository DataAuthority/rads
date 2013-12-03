json.array!(@project_memberships) do |project_membership|
  json.extract! project_membership, :project_id, :user_id
  json.url project_project_membership_url(@project, project_membership, format: :json)
end
