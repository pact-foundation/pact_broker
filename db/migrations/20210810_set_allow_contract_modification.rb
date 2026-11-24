Sequel.migration do
  up do
    if from(:pact_publications).count != 0
      from(:config).insert(
        name: "allow_dangerous_contract_modification",
        type: "boolean",
        value: "1",
        created_at: Time.now,
        updated_at: Time.now
      )
    end
  end

  down do

  end
end
