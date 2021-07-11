Sequel.migration do
  change do
    alter_table(:pact_publications) do
      add_column(:consumer_version_order, Integer) # duplicate column, no need for referential integrity
    end

    # TODO
    # alter_table(:pact_publications) do
    #   set_column_not_null(:consumer_version_order)
    # end
  end
end
