json.array!(@core_memberships) do |core_membership|
  json.extract! core_membership, :core_id, :repository_user_id
  json.url core_core_membership_url(@core, core_membership, format: :json)
end
