Sequel.migration do
  change do
    alter_table(:pacts) do
      set_column_type(:json_content, :mediumtext)
    end
  end
end

