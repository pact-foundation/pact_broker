Sequel.migration do
  change do
    create_table(:tags) do
      String :name
      foreign_key :version_id, :versions
      primary_key [:version_id, :name], :name=>:tags_pk
    end
  end
end

