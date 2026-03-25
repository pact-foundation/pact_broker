Sequel.migration do
  change do
    create_table(:version_sequence_number) do
      Integer :value, null: false
    end
  end
end
