Sequel.migration do
  change do
    alter_table(:materialized_head_matrix) do
      add_index(:consumer_version_tag_name)
    end
  end
end
