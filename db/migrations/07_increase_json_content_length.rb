Sequel.migration do
  change do
    alter_table(:pacts) do
      if Sequel::Model.db.adapter_scheme == :postgres
        set_column_type(:json_content, :text)
      else
        # Assume mysql
        set_column_type(:json_content, :mediumtext)
      end
    end
  end
end

