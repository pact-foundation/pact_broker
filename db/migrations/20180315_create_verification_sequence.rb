Sequel.migration do
  up do
    create_table(:verification_sequence_number) do
      Integer :value, null: false
    end

    start = (from(:verifications).max(:number) || 0) + 100
    from(:verification_sequence_number).insert(value: start)
  end

  down do
    drop_table(:verification_sequence_number)
  end
end
