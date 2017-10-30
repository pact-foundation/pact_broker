Sequel.migration do

  change do
    create_table(:versions, charset: 'utf8') do
      primary_key :id
      String :number
      String :repository_ref
      foreign_key :pacticipant_id, :pacticipants, :null=>false
      index [:pacticipant_id, :number], :unique=>true
    end
  end

end

