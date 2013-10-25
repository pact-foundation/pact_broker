Sequel.migration do

  change do
    create_table(:versions) do
      primary_key :id
      String :number, :unique => true
      String :repository_ref
    end
  end

end

