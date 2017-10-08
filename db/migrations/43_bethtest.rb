Sequel.migration do
  up do
    add_column(:pact_versions, :verifiable_content_sha, String)
  end
end


